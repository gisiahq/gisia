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
    @epics = EpicsFinder.new(@project, current_user, filter_params).execute
                        .includes(:author, :updated_by, :closed_by, :labels)
                        .page(params[:page])
                        .per(20)

    @label_options = @project.available_labels.order(:title)
    @sort_scopes = @label_options.map(&:title).grep(/::/).map { |t| t.split('::').first }.uniq
    @user_options = @project.users.active.order(:username)

    @pagination_params = params.permit(:status, :search, :author, :assignee, :sort, label: [])
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
    @users = @project.users.active.limit(10)

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
    @labels = @project.available_labels.limit(10)

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
    @epic.relink_label_ids(available_label_ids)
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

  def filter_params
    params.permit(:status, :search, :author, :assignee, :sort, label: [])
  end

  def epic_params
    params.require(:epic).permit(:title, :description, :confidential, :due_date, :parent_id, assignee_ids: [])
  end

  def label_params
    params.dig(:epic, :label_ids)&.map(&:to_i) || []
  end

  def available_label_ids
    return [] if label_params.empty?

    @project.available_labels.where(id: label_params).pluck(:id)
  end

  def unlink_label_params
    params[:label_id]
  end
end
