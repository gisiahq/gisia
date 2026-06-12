module Projects
  module Settings
    class MembersController < Projects::Settings::ApplicationController
      include MembersHelper
      include Projects::MemberRoleAuthorizable
      before_action :set_member, only: [:edit_form, :update, :destroy]
      before_action :authorize_member_role!, only: [:create, :update, :destroy]
      before_action :prevent_last_owner_removal!, only: [:destroy]

      def index
        @members = @project.namespace.members.includes(:user).non_request.order(access_level: :desc, id: :asc)
      end

      def new_form
        @users = User.active.where.not(id: @project.namespace.members.select(:user_id))

        respond_to do |format|
          format.html
          format.turbo_stream { render :new_form }
        end
      end

      def create
        @member = @project.namespace.members.build(member_params)

        if @member.save
          @members = @project.namespace.members.includes(:user).non_request.order(access_level: :desc, id: :asc)

          respond_to do |format|
            format.turbo_stream { render :create }
            format.html { redirect_to settings_members_path(@project), notice: 'Member was successfully added.' }
          end
        else
          @users = User.active.where.not(id: @project.namespace.members.select(:user_id))

          respond_to do |format|
            format.turbo_stream { render :new_form }
            format.html { redirect_to settings_members_path(@project), alert: @member.errors.full_messages.join(', ') }
          end
        end
      end

      def edit_form
        respond_to do |format|
          format.turbo_stream { render :edit_form }
        end
      end

      def update
        if @member.update(member_params)
          @members = @project.namespace.members.includes(:user).non_request.order(access_level: :desc, id: :asc)

          respond_to do |format|
            format.turbo_stream { render :update }
            format.html { redirect_to settings_members_path(@project), notice: 'Member was successfully updated.' }
          end
        else
          respond_to do |format|
            format.turbo_stream { render :edit_form }
            format.html { redirect_to settings_members_path(@project), alert: @member.errors.full_messages.join(', ') }
          end
        end
      end

      def destroy
        @member.destroy

        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.remove("member-#{@member.id}") }
          format.html { redirect_to settings_members_path(@project), notice: 'Member was successfully removed.' }
        end
      end

      private

      def set_member
        @member = @project.namespace.members.find(params[:id])
      end

      def prevent_last_owner_removal!
        return unless last_owner?(@member)

        redirect_to settings_members_path(@project), alert: 'Cannot remove the last owner of the project.'
      end

      def requested_access_level
        return unless params.key?(:project_member) || params.key?(:member)

        member_params[:access_level]
      end

      def deny_member_access!
        head :forbidden
      end

      def member_params
        key = params.key?(:project_member) ? :project_member : :member
        params.require(key).permit(:user_id, :access_level, :expires_at)
      end
    end
  end
end
