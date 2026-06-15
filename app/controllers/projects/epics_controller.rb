class Projects::EpicsController < Projects::ApplicationController
  include Projects::IssueAuthorizable
  include Projects::SetsUpdatedBy

  before_action :authorize_read_issues!, only: [:index, :search_users, :search_epics]
  before_action :authorize_create_issue!, only: [:new, :create]
  before_action :set_epic, only: [:show, :edit, :update, :destroy, :close, :reopen, :link_labels, :unlink_label, :search_labels]
  before_action :set_notification_author, only: [:update, :close, :reopen, :link_labels, :unlink_label]
  before_action :authorize_read_issuable!, only: [:show, :search_labels]
  before_action :authorize_update_issuable!, only: [:edit, :update, :close, :reopen, :link_labels, :unlink_label]
  before_action :authorize_destroy_issuable!, only: [:destroy]
  before_action :set_counts, only: [:index]
  before_action :set_updated_by, only: [:update, :link_labels, :unlink_label]

  def index
    status_param = params[:status].presence || 'opened'
    search_params = {
      state_id_eq: WorkItems::HasState::STATE_ID_MAP[status_param],
      author_id_eq: params[:author_id],
      title_or_description_i_cont: params[:search]
    }.compact

    @epics = @project.namespace.work_items.where(type: 'Epic')
                     .ransack(search_params)
                     .result(distinct: true)

    @epics = filter_by_labels(@epics, params[:labels]) if params[:labels].present?

    order_column = status_param == 'closed' ? { closed_at: :desc } : { created_at: :desc }
    @epics = @epics.includes(:author, :updated_by, :closed_by, :labels)
                     .order(order_column)
                     .page(params[:page])
                     .per(20)
  end

  def show
    @activities = @epic.activities.chronological
                       .includes(:author, note: [:author, :updated_by, :resolved_by, replies: [:author, :updated_by]])
  end

  def new
    @epic = Epic.new
  end

  def create
    @epic = @project.namespace.epics.build(epic_params)
    @epic.author = current_user
    @epic.notification_author = current_user
    @epic.activity_author = current_user

    if @epic.save
      redirect_to namespace_project_epic_path(@project.namespace.parent.full_path, @project.path, @epic), notice: 'Epic was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @epic.update(epic_params)
      respond_to do |format|
        format.html { redirect_to namespace_project_epic_path(@project.namespace.parent.full_path, @project.path, @epic), notice: 'Epic was successfully updated.' }
        format.turbo_stream { render :update }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :update_error, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @epic.destroy
    redirect_to namespace_project_epics_path(@project.namespace.parent.full_path, @project.path), notice: 'Epic was successfully deleted.'
  end

  def close
    @epic.close!(current_user)
    redirect_to namespace_project_epic_path(@project.namespace.parent.full_path, @project.path, @epic), notice: 'Epic was closed.'
  end

  def reopen
    @epic.reopen!
    redirect_to namespace_project_epic_path(@project.namespace.parent.full_path, @project.path, @epic), notice: 'Epic was reopened.'
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

    @selected_ids = @epic.label_ids

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

  def link_labels
    @epic.relink_label_ids(label_params)
    @epic.save
    @epic.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  def unlink_label
    label_id = unlink_label_params.to_i
    @epic.label_ids = @epic.label_ids - [label_id]
    @epic.save
    @epic.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def issuable_resource
    @epic
  end

  def set_notification_author
    @epic.notification_author = current_user
    @epic.activity_author = current_user
  end

  def authorization_denied!
    head :not_found
  end

  def set_epic
    @epic = @project.namespace.work_items.where(type: 'Epic').find_by!(iid: params[:iid])
  end

  def set_counts
    @opened_count = @project.namespace.work_items.where(type: 'Epic', state_id: WorkItems::HasState::STATE_ID_MAP['opened']).count
    @closed_count = @project.namespace.work_items.where(type: 'Epic', state_id: WorkItems::HasState::STATE_ID_MAP['closed']).count
  end

  def filter_by_labels(epics, labels_param)
    label_titles = labels_param.include?('|') ? labels_param.split('|').map(&:strip) : labels_param.split(',').map(&:strip)

    if labels_param.include?('|')
      epics.joins(:labels).where(labels: { title: label_titles }).distinct
    else
      label_link_ids = LabelLink.joins(:label).joins("INNER JOIN work_items ON work_items.id = label_links.labelable_id AND label_links.labelable_type = 'WorkItem'").where(labels: { title: label_titles }, work_items: { namespace_id: @project.namespace_id }).group('labelable_id').having('COUNT(*) = ?', label_titles.size).pluck('labelable_id')
      epics.where(id: label_link_ids)
    end
  end

  def epic_params
    params.require(:epic).permit(:title, :description, :confidential, :due_date, :parent_id, assignee_ids: [])
  end

  def label_params
    params.dig(:epic, :label_ids)&.map(&:to_i) || []
  end

  def unlink_label_params
    params[:label_id]
  end
end
