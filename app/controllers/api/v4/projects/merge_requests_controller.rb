# frozen_string_literal: true

module API
  module V4
    module Projects
      class MergeRequestsController < ::API::V4::ProjectBaseController
        include ::Projects::MergeRequestAuthorizable
        include ::Projects::MergeRequestNotifiable

        before_action :require_project_member!, only: [:create, :update, :destroy]
        before_action :find_merge_request!, only: [:show, :update, :destroy]
        before_action :authorize_read_merge_requests!, only: [:index]
        before_action :authorize_create_merge_request!, only: [:create]
        before_action :authorize_read_merge_request!, only: [:show]
        before_action :authorize_update_merge_request!, only: [:update]
        before_action :authorize_destroy_merge_request!, only: [:destroy]
        before_action :set_notification_author, only: [:update]

        def index
          state = params[:state].presence
          search_params = {
            status_eq: (state && state != 'all') ? MergeRequest.statuses[state] : nil,
            assignees_id_eq: params[:assignee_id],
            reviewers_id_eq: params[:reviewer_id],
            author_id_eq: params[:author_id],
            title_or_description_i_cont: params[:search],
            source_branch_eq: params[:source_branch],
            target_branch_eq: params[:target_branch]
          }.compact

          order_clause = case state
                         when 'closed' then 'merge_request_metrics.latest_closed_at DESC NULLS LAST'
                         when 'merged' then 'merge_request_metrics.merged_at DESC NULLS LAST'
                         end

          base = @project.merge_requests.ransack(search_params).result(distinct: true)
          mrs = if order_clause
                  MergeRequest.where(id: base.select(:id)).joins(:metrics).order(Arel.sql(order_clause))
                else
                  base.order(id: :desc)
                end
          mrs = mrs.includes(:author, :assignees, :reviewers, :metrics, target_project: { namespace: :parent })

          @merge_requests = paginate(mrs)
        end

        def show; end

        def create
          @merge_request = MergeRequest.new(create_params)
          @merge_request.author = current_user
          @merge_request.source_project = @project
          @merge_request.target_project = @project

          @merge_request.notification_author = current_user
          @merge_request.activity_author = current_user
          if @merge_request.save
            handle_assignees(params[:assignee_ids])
            handle_reviewers(params[:reviewer_ids])
            render :show, status: :created
          else
            render json: { message: @merge_request.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          success = false
          state_event = params[:state_event]
          previous_assignee_ids = @merge_request.assignees.map(&:id).sort if params.key?(:assignee_ids)

          ApplicationRecord.transaction do
            handle_state_event(state_event)
            attrs = update_params
            attrs[:assignee_ids] = Array(params[:assignee_ids]) if params.key?(:assignee_ids)
            attrs[:reviewer_ids] = Array(params[:reviewer_ids]) if params.key?(:reviewer_ids)
            success = attrs.empty? || @merge_request.update(attrs)
            raise ActiveRecord::Rollback unless success
          end

          if success
            notify_mr_update(state_event, previous_assignee_ids)
            render :show
          else
            render json: { message: @merge_request.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @merge_request.destroy
          head :no_content
        end

        private

        def set_notification_author
          @merge_request.notification_author = current_user
          @merge_request.activity_author = current_user
        end

        def find_merge_request!
          @merge_request = @project.merge_requests
            .includes(:author, :assignees, :reviewers, :metrics, target_project: { namespace: :parent })
            .find_by(iid: params[:merge_request_iid])
          not_found! unless @merge_request
        end

        def handle_assignees(assignee_ids)
          return unless assignee_ids

          @merge_request.assignees = User.where(id: Array(assignee_ids))
        end

        def handle_reviewers(reviewer_ids)
          return unless reviewer_ids

          @merge_request.reviewers = User.where(id: Array(reviewer_ids))
        end

        def create_params
          p = params.permit(:source_branch, :target_branch, :title, :description).compact
          p[:title] = "Merge #{p[:source_branch]} into #{p[:target_branch]}" if p[:title].blank?
          p
        end

        def update_params
          params.permit(:title, :description).compact
        end
      end
    end
  end
end
