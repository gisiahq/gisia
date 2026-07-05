# frozen_string_literal: true

module API
  module V4
    module Groups
      class MembersController < ::API::V4::UserBaseController
        include ::Groups::MemberRoleAuthorizable

        before_action :find_group!
        before_action :find_member!, only: [:show, :update, :destroy]
        before_action :authorize_manage_members!, only: [:index, :create, :update, :destroy]
        before_action :authorize_member_role!, only: [:create, :update, :destroy]
        before_action :prevent_last_owner_removal!, only: [:destroy]

        def index
          @members = GroupMember.with_namespace(@namespace).includes(:user)
        end

        def show; end

        def create
          user = User.find_by(id: member_params[:user_id])
          return not_found! unless user

          @member = GroupMember.new(
            user: user,
            namespace: @namespace,
            access_level: member_params[:access_level],
            expires_at: member_params[:expires_at],
            created_by: current_user
          )

          if @member.save
            render :show, status: :created
          else
            render json: { message: @member.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotUnique
          render json: { message: ['User is already a member of this group'] }, status: :unprocessable_entity
        end

        def update
          update_params = { access_level: member_params[:access_level] }
          update_params[:expires_at] = member_params[:expires_at] if member_params.key?(:expires_at)
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

        def find_group!
          ns = Namespace.without_project_namespaces.find_by_id_or_path(params[:group_id])
          not_found! unless ns&.group_namespace?

          @namespace = ns
        end

        def find_member!
          @member = GroupMember.with_namespace(@namespace).find_by(user_id: member_params[:user_id])
          not_found! unless @member
        end

        def authorize_manage_members!
          return if current_user&.admin?

          forbidden! unless actor_access_level >= Accessible::MAINTAINER
        end

        def prevent_last_owner_removal!
          return unless last_owner?(@member)

          forbidden!('Cannot remove the last owner of the group')
        end

        def requested_access_level
          member_params[:access_level]
        end

        def deny_member_access!
          forbidden!
        end

        def member_params
          @member_params ||= params.permit(:user_id, :access_level, :expires_at)
        end
      end
    end
  end
end
