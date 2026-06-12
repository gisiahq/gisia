# frozen_string_literal: true

module API
  module V4
    module Projects
      class MembersController < ::API::V4::ProjectBaseController
        include ::Projects::MemberRoleAuthorizable

        before_action :find_member!, only: [:show, :update, :destroy]
        before_action :authorize_manage_members!, only: [:index, :create, :update, :destroy]
        before_action :authorize_member_role!, only: [:create, :update, :destroy]
        before_action :prevent_last_owner_removal!, only: [:destroy]

        def index
          @members = ProjectMember.with_project(@project).includes(:user)
        end

        def show; end

        def create
          user = User.find_by(id: params[:user_id])
          return not_found! unless user

          @member = ProjectMember.new(
            user: user,
            namespace: @project.namespace,
            access_level: params[:access_level],
            expires_at: params[:expires_at],
            created_by: current_user
          )

          if @member.save
            render :show, status: :created
          else
            render json: { message: @member.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotUnique
          render json: { message: ['User is already a member of this project'] }, status: :unprocessable_entity
        end

        def update
          update_params = { access_level: params[:access_level] }
          update_params[:expires_at] = params[:expires_at] if params.key?(:expires_at)
          if @member.update(update_params)
            render :show
          else
            render json: { message: @member.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @member.destroy
          head :no_content
        end

        private

        def find_member!
          @member = ProjectMember.with_project(@project).find_by(user_id: params[:user_id])
          not_found! unless @member
        end

        def authorize_manage_members!
          return if current_user&.admin?

          member = ProjectMember.with_project(@project).find_by(user_id: current_user&.id)
          forbidden! unless member&.maintainer? || member&.owner?
        end

        def prevent_last_owner_removal!
          return unless last_owner?(@member)

          forbidden!('Cannot remove the last owner of the project')
        end

        def requested_access_level
          params[:access_level]
        end

        def deny_member_access!
          forbidden!
        end
      end
    end
  end
end
