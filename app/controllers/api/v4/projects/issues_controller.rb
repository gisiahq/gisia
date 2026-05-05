# frozen_string_literal: true

module API
  module V4
    module Projects
      class IssuesController < ::API::V4::ProjectBaseController
        include API::V4::IssueFilterable
        include ::Projects::IssueAuthorizable
        include ::Projects::SetsUpdatedBy

        before_action :find_issue!, only: [:show, :update, :destroy]
        before_action :check_issue_visibility!, only: [:show, :update, :destroy]
        before_action :authorize_read_issues!, only: [:index]
        before_action :authorize_create_issue!, only: [:create]
        before_action :authorize_read_issuable!, only: [:show]
        before_action :authorize_update_issuable!, only: [:update]
        before_action :authorize_destroy_issuable!, only: [:destroy]
        before_action :set_notification_author, only: [:update]
        before_action :set_updated_by, only: [:update]

        def index
          order_column = params[:state] == 'closed' ? { closed_at: :desc } : { created_at: :desc }
          @issues = paginate(apply_filters(@project.issues_visible_to(current_user)).order(order_column))
        end

        def show; end

        def create
          @issue = Issue.new(create_params)
          @issue.namespace = @project.namespace
          @issue.author = current_user
          @issue.notification_author = current_user
          @issue.activity_author = current_user

          if @issue.save
            handle_assignees(@issue, params[:assignee_ids])
            handle_labels(@issue, params[:label_ids])
            render :show, status: :created
          else
            render json: { message: @issue.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          handle_state_event
          handle_add_labels
          handle_remove_labels
          return unless set_epic_parent

          attrs = update_params
          attrs[:assignee_ids] = Array(params[:assignee_ids]) if params.key?(:assignee_ids)

          if @issue.update(attrs)
            render :show
          else
            render json: { message: @issue.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @issue.destroy
          head :no_content
        end

        private

        def set_notification_author
          @issue.notification_author = current_user
          @issue.activity_author = current_user
        end

        def issuable_resource
          @issue
        end

        def find_issue!
          @issue = @project.issues.find_by(iid: params[:issue_iid])
          not_found! unless @issue
        end

        def check_issue_visibility!
          not_found! if @issue.confidential? && !can?(current_user, :read_issue, @issue)
        end

        def label_scope
          Label.where(namespace_id: @project.namespace_id)
        end

        def handle_state_event
          case params[:state_event]
          when 'close'
            @issue.close!(current_user) unless @issue.closed?
          when 'reopen'
            @issue.reopen! unless @issue.opened?
          end
        end

        def handle_assignees(issue, assignee_ids)
          return unless assignee_ids

          issue.assignees = User.where(id: Array(assignee_ids))
        end

        def handle_labels(issue, label_ids)
          return if label_ids.blank?

          issue.labels = label_scope.where(id: Array(label_ids))
        end

        def handle_add_labels
          return if params[:add_label_ids].blank?

          new_ids = label_scope.where(id: Array(params[:add_label_ids])).pluck(:id)
          @issue.label_ids = @issue.label_ids | new_ids
        end

        def handle_remove_labels
          return if params[:remove_label_ids].blank?

          remove_ids = Array(params[:remove_label_ids]).map(&:to_i)
          @issue.label_ids = @issue.label_ids - remove_ids
        end

        def set_epic_parent
          return true unless params.key?(:epic_id)

          if params[:epic_id].blank?
            @issue.parent_id = nil
            return true
          end

          epic = @project.namespace.epics.find_by(id: params[:epic_id])
          unless epic
            not_found!
            return false
          end

          @issue.parent_id = epic.id
          true
        end

        def create_params
          params.permit(:title, :description, :due_date, :confidential).compact
        end

        def update_params
          params.permit(:title, :description, :due_date, :confidential).compact
        end
      end
    end
  end
end
