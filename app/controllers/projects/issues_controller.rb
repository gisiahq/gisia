class Projects::IssuesController < Projects::ApplicationController
  include StageIssuesFilterable
  include Projects::IssueAuthorizable
  include Projects::SetsUpdatedBy
  include Projects::ItemLinkFindable

  before_action :authorize_read_issues!, only: [:index, :search_users, :search_epics, :search_links]
  before_action :authorize_create_issue!, only: [:new, :create]
  before_action :set_issue, only: [:show, :edit, :update, :destroy, :close, :reopen, :move_stage, :link_labels, :unlink_label, :search_labels, :search_links]
  before_action :authorize_read_issuable!, only: [:show, :search_labels]
  before_action :authorize_update_issuable!, only: [:edit, :update, :close, :reopen, :move_stage, :link_labels, :unlink_label]
  before_action :authorize_destroy_issuable!, only: [:destroy]
  before_action :set_counts, only: [:index]
  before_action :set_notification_author, only: [:update, :close, :reopen, :link_labels, :unlink_label]
  before_action :set_updated_by, only: [:update, :move_stage, :link_labels, :unlink_label]

  def index
    status_param = params[:status].presence || 'opened'
    search_params = {
      state_id_eq: WorkItems::HasState::STATE_ID_MAP[status_param],
      author_id_eq: params[:author_id],
      title_or_description_i_cont: params[:search]
    }.compact

    @issues = @project.issues_visible_to(current_user)
                     .ransack(search_params)
                     .result(distinct: true)

    @issues = filter_by_labels(@issues, params[:labels]) if params[:labels].present?

    order_column = status_param == 'closed' ? { closed_at: :desc } : { created_at: :desc }
    @issues = @issues.includes(:author, :updated_by, :closed_by, :labels)
                     .order(order_column)
                     .page(params[:page])
                     .per(20)
  end

  def show
    @activities = @issue.activities.chronological
                        .includes(:author, note: [:author, :updated_by, :resolved_by, replies: [:author, :updated_by]])
  end

  def new
    @issue = Issue.new
  end

  def create
    @issue = @project.namespace.issues.build(issue_params)
    @issue.author = current_user

    @issue.notification_author = current_user
    @issue.activity_author = current_user

    if @issue.save
      redirect_to namespace_project_issue_path(@project.namespace.parent.full_path, @project.path, @issue), notice: 'Issue was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @issue.update(issue_params)
      respond_to do |format|
        format.html do
          redirect_to namespace_project_issue_path(@project.namespace.parent.full_path, @project.path, @issue), notice: 'Issue was successfully updated.'
        end
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :update_error, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @issue.destroy
    redirect_to namespace_project_issues_path(@project.namespace.parent.full_path, @project.path), notice: 'Issue was successfully deleted.'
  end

  def close
    @issue.close!(current_user)
    redirect_to namespace_project_issue_path(@project.namespace.parent.full_path, @project.path, @issue), notice: 'Issue was closed.'
  end

  def reopen
    @issue.reopen!
    redirect_to namespace_project_issue_path(@project.namespace.parent.full_path, @project.path, @issue), notice: 'Issue was reopened.'
  end

  def move_stage
    @to_stage = @project.namespace.board.stages.find(params[:to_stage_id])
    @from_stage = @project.namespace.board.stages.find(params[:from_stage_id])
    @board = @project.namespace.board
    @can_edit_board = can_edit_board?

    return head :no_content if @from_stage == @to_stage
    return head :no_content if @issue.closed?

    @issue.relink_label_ids(@to_stage.label_ids)
    @issue.save

    @issue.close!(current_user) if @to_stage.kind == 'closed'

    @from_stage_issues = issues_for_stage(@from_stage) if @from_stage
    @to_stage_issues = issues_for_stage(@to_stage)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def link_labels
    @issue.relink_label_ids(label_params)
    @issue.save

    respond_to do |format|
      format.turbo_stream
    end
  end

  def unlink_label
    label_id = unlink_label_params.to_i
    @issue.label_ids = @issue.label_ids - [label_id]
    @issue.save
    @issue.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  def search_users
    @users = @project.users.limit(10)

    @users = if params[:ids]
               @users.where(id: params[:ids].split(',').map(&:to_i))
             elsif params[:q]
               @users.ransack(username_or_name_cont: params[:q]).result
             end

    @field_type = params[:field_type] || 'assignees'
    @selected_ids = params[:selected_ids]&.split(',')&.map(&:to_i) || []

    respond_to do |format|
      format.json
      format.turbo_stream
    end
  end

  def search_labels
    @labels = @project.namespace.labels.limit(10)

    @labels = @labels.ransack(title_cont: params[:q]).result if params[:q]

    @selected_ids = @issue.label_ids

    respond_to do |format|
      format.turbo_stream
    end
  end

  def search_epics
    @epics = @project.namespace.epics.opened.limit(10)
    @epics = @epics.ransack(title_cont: params[:q]).result if params[:q]
    @selected_id = params[:selected_id]&.to_i

    respond_to do |format|
      format.turbo_stream
    end
  end

  def search_links
    @results = search_link_item_results(params[:q].to_s.strip)
    respond_to { |format| format.turbo_stream }
  end

  private

  def set_notification_author
    @issue.notification_author = current_user
    @issue.activity_author = current_user
  end

  def issuable_resource
    @issue
  end

  def authorization_denied!
    head :not_found
  end

  def set_issue
    @issue = @project.namespace.work_items.where(type: 'Issue').find_by!(iid: params[:iid])
  end

  def set_counts
    @opened_count = @project.namespace.work_items.where(type: 'Issue', state_id: WorkItems::HasState::STATE_ID_MAP['opened']).count
    @closed_count = @project.namespace.work_items.where(type: 'Issue', state_id: WorkItems::HasState::STATE_ID_MAP['closed']).count
  end

  def filter_by_labels(issues, labels_param)
    label_titles = labels_param.include?('|') ? labels_param.split('|').map(&:strip) : labels_param.split(',').map(&:strip)

    if labels_param.include?('|')
      issues.joins(:labels).where(labels: { title: label_titles }).distinct
    else
      label_link_ids = LabelLink.joins(:label).joins("INNER JOIN work_items ON work_items.id = label_links.labelable_id AND label_links.labelable_type = 'WorkItem'").where(labels: { title: label_titles }, work_items: { namespace_id: @project.namespace_id }).group('labelable_id').having('COUNT(*) = ?', label_titles.size).pluck('labelable_id')
      issues.where(id: label_link_ids)
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :description, :confidential, :due_date, :parent_id, assignee_ids: [])
  end

  def label_params
    params.dig(:issue, :label_ids)&.map(&:to_i) || []
  end

  def unlink_label_params
    params[:label_id]
  end
end
