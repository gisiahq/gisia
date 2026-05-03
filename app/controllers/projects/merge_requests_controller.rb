# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Projects::MergeRequestsController < Projects::ApplicationController
  include Projects::MergeRequestNotifiable
  include Projects::MergeRequestAuthorizable
  include Projects::ItemLinkFindable
  before_action :authenticate_user!, only: %i[new create edit update merge]
  before_action :require_project_member!, only: %i[new create edit update merge]
  before_action :define_new_vars, only: %i[new edit]
  before_action :set_mr, only: %i[show commits diffs pipelines edit update merge search_links]
  before_action :set_counts, only: [:index]
  before_action :authorize_create_merge_request!, only: %i[new create]
  before_action :authorize_read_merge_request!, only: %i[show commits diffs pipelines search_links]
  before_action :authorize_update_merge_request!, only: %i[edit update merge]
  before_action :set_notification_author, only: [:update]
  before_action :check_mr_open, only: [:edit]

  def index
    status_param = params[:status].presence || 'opened'
    search_params = {
      status_eq: MergeRequest.statuses[status_param],
      assignees_id_eq: params[:assignee_id],
      reviewers_id_eq: params[:reviewer_id],
      author_id_eq: params[:author_id],
      title_or_description_i_cont: params[:search]
    }.compact

    order_clause = case status_param
                   when 'closed' then 'merge_request_metrics.latest_closed_at DESC NULLS LAST'
                   when 'merged' then 'merge_request_metrics.merged_at DESC NULLS LAST'
                   end

    base = project.merge_requests.ransack(search_params).result(distinct: true)
    @merge_requests = if order_clause
                        MergeRequest.where(id: base.select(:id)).joins(:metrics).order(Arel.sql(order_clause))
                      else
                        base.order(id: :desc)
                      end
    @merge_requests = @merge_requests.includes(:author, :assignees, :reviewers, metrics: :latest_closed_by)
                                     .page(params[:page])
                                     .per(20)
  end

  def new; end

  def show
    @activities = @merge_request.activities.chronological
                                .includes(:author, note: [:author, :updated_by, :resolved_by, replies: [:author, :updated_by, :resolved_by]])
  end

  def search_links
    @results = search_link_item_results(params[:q].to_s.strip)
    respond_to { |format| format.turbo_stream }
  end

  def commits
    @commits = @merge_request.recent_commits
  end

  def create
    @merge_request = MergeRequest.new(merge_request_create_params)
    @merge_request.notification_author = current_user
    @merge_request.activity_author = current_user

    if @merge_request.save
      redirect_to namespace_project_merge_request_path(@merge_request.target_project.namespace.parent.full_path, @merge_request.target_project.path, @merge_request),
        notice: 'Merge request was successfully created.'
    else
      define_new_vars
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    success = false
    mr_params = merge_request_params
    state_event = mr_params.delete(:state_event)
    previous_assignee_ids = @merge_request.assignees.map(&:id).sort if mr_params.key?(:assignee_ids)

    ApplicationRecord.transaction do
      handle_state_event(state_event)
      success = @merge_request.errors.none? && (mr_params.empty? || @merge_request.update(mr_params))
      raise ActiveRecord::Rollback unless success
    end

    if success
      notify_mr_update(state_event, previous_assignee_ids)
      respond_to do |format|
        format.html do
          redirect_to namespace_project_merge_request_path(@merge_request.target_project.namespace.parent.full_path, @merge_request.target_project.path, @merge_request),
            notice: 'Merge request was successfully updated.'
        end
        format.json { render json: { status: 'success', message: 'Merge request was successfully updated.' } }
        format.turbo_stream do
          state_event.present? ? redirect_to(namespace_project_merge_request_path(@merge_request.target_project.namespace.parent.full_path, @merge_request.target_project.path, @merge_request), notice: 'Merge request was successfully updated.') : render(:update)
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { status: 'error', errors: @merge_request.errors }, status: :unprocessable_entity }
        format.turbo_stream do
          flash.now[:alert] = @merge_request.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash')
        end
      end
    end
  end

  def merge
    result = MergeRequests::MergeService.new(merge_request: @merge_request, current_user: current_user).execute
    mr_path = namespace_project_merge_request_path(@merge_request.target_project.namespace.parent.full_path, @merge_request.target_project.path, @merge_request)

    if result[:status] == :success
      redirect_to mr_path, notice: 'Merge request was successfully merged.'
    else
      redirect_to mr_path, alert: result[:message]
    end
  end

  def diffs
    @diff_version = @merge_request.merge_request_diffs.viewable.find_by(id: params[:diff_id]) if params[:diff_id].present?

    @diffs = if @diff_version && params[:start_sha].present?
      comparison = MergeRequests::MergeRequestDiffComparison.new(@diff_version).compare_with(params[:start_sha])
      comparison ? comparison.diffs : @diff_version.diffs
    elsif @diff_version
      @diff_version.diffs
    else
      @merge_request.diffs
    end

    @grouped_diff_discussions = @merge_request.notes.grouped_diff_discussions(@diffs.diff_refs)

    file_sha = params[:diff_anchor]&.split('_')&.first
    @selected_file_index = if file_sha.present?
      @diffs.diff_files.find_index { |f| Digest::SHA1.hexdigest(f.file_path) == file_sha } || 0
    else
      0
    end
  end

  def pipelines
    @pipelines = @merge_request.pipelines
  end

  def search_users
    @users = project.users.limit(10)

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

  private

  def merge_request_params
    params.require(:merge_request).permit(:source_project_id, :source_branch, :target_project_id, :target_branch, :title, :description, :state_event,
      assignee_ids: [], reviewer_ids: [])
  end

  def merge_request_create_params
    mr_params = merge_request_params.merge(author_id: current_user.id, source_project: project, target_project: project)
    mr_params[:title] = "Merge #{mr_params[:source_branch]} into #{mr_params[:target_branch]}" if mr_params[:title].blank?
    mr_params
  end

  def define_new_vars
    @merge_request ||= MergeRequest.new(source_project: project, target_project: project)
    @branches = project.repository.branch_names
    @projects = Project.all
    @users = project.users
  end

  def set_mr
    @merge_request = project.merge_requests.includes(:assignees, :reviewers).find_by!(iid: params[:iid])
  end

  def set_counts
    @opened_count = project.merge_requests.opened.count
    @merged_count = project.merge_requests.merged.count
    @closed_count = project.merge_requests.closed.count
  end

  def set_notification_author
    @merge_request.notification_author = current_user
    @merge_request.activity_author = current_user
  end

  def check_mr_open
    return if @merge_request.opened?

    redirect_to namespace_project_merge_request_path(@merge_request.target_project.namespace.parent.full_path, @merge_request.target_project.path, @merge_request),
      alert: 'This merge request is no longer open and cannot be edited.'
  end
end
