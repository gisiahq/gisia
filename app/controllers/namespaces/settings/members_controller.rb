# frozen_string_literal: true

module Namespaces
  module Settings
    class MembersController < Namespaces::Settings::ApplicationController
      include ::Groups::MemberRoleAuthorizable

      helper_method :assignable_access_levels

      before_action :set_member, only: [:edit_form, :update, :destroy]
      before_action :authorize_member_role!, only: [:create, :update, :destroy]
      before_action :prevent_last_owner_removal!, only: [:destroy]
      before_action :prevent_last_owner_demotion!, only: [:update]

      def index
        @members = member_rows
      end

      def new_form
        @users = available_users

        respond_to do |format|
          format.html
          format.turbo_stream { render :new_form }
        end
      end

      def create
        @member = @namespace.members.build(member_params)

        if @member.save
          @members = member_rows

          respond_to do |format|
            format.turbo_stream { render :create }
            format.html { redirect_to members_page_path, notice: _('Member was successfully added.') }
          end
        else
          @users = available_users
          flash.now[:alert] = @member.errors.full_messages.join(', ')

          respond_to do |format|
            format.turbo_stream { render :new_form }
            format.html { redirect_to members_page_path, alert: @member.errors.full_messages.join(', ') }
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
          @members = member_rows

          respond_to do |format|
            format.turbo_stream { render :update }
            format.html { redirect_to members_page_path, notice: _('Member was successfully updated.') }
          end
        else
          flash.now[:alert] = @member.errors.full_messages.join(', ')

          respond_to do |format|
            format.turbo_stream { render :edit_form }
            format.html { redirect_to members_page_path, alert: @member.errors.full_messages.join(', ') }
          end
        end
      end

      def destroy
        @member.destroy

        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.remove("member-#{@member.id}") }
          format.html { redirect_to members_page_path, notice: _('Member was successfully removed.') }
        end
      end

      private

      def member_rows
        GroupMember.members_for_listing(@namespace)
          .includes(:user, :namespace)
          .order(access_level: :desc, id: :asc)
      end

      def available_users
        User.available_for_membership_in(@namespace)
      end

      def set_member
        @member = @namespace.members.find(params[:id])
      end

      def prevent_last_owner_removal!
        return unless last_owner?(@member)

        reject_with_flash(_('Cannot remove the last owner of the group.'))
      end

      def prevent_last_owner_demotion!
        return unless last_owner?(@member)

        level = requested_access_level
        return if level.blank? || normalize_access_level(level) >= Gitlab::Access::OWNER

        reject_with_flash(_('Cannot demote the last owner of the group.'))
      end

      def reject_with_flash(message)
        respond_to do |format|
          format.html { redirect_to members_page_path, alert: message }
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash')
          end
        end
      end

      def members_page_path
        namespace_settings_members_path(@namespace.full_path)
      end

      def requested_access_level
        return unless params.key?(:group_member) || params.key?(:member)

        member_params[:access_level]
      end

      def deny_member_access!
        head :forbidden
      end

      def member_params
        key = params.key?(:group_member) ? :group_member : :member
        @member_params ||= params.require(key).permit(:user_id, :access_level, :expires_at)
      end
    end
  end
end
