# frozen_string_literal: true

module Projects
  module MemberRoleAuthorizable
    extend ActiveSupport::Concern

    private

    def authorize_member_role!
      return deny_member_access! if @member && !can_assign_level?(@member.access_level)

      level = requested_access_level
      deny_member_access! if level.present? && !can_assign_level?(level)
    end

    def can_assign_level?(level)
      return true if current_user&.admin?

      Gitlab::Access.level_encompasses?(
        current_access_level: actor_access_level,
        level_to_assign: normalize_access_level(level)
      )
    end

    def actor_access_level
      @actor_access_level ||= @project.team.max_member_access(current_user.id)
    end

    def normalize_access_level(level)
      Member.access_levels.fetch(level.to_s, level).to_i
    end

    def last_owner?(member)
      return false unless member.owner?

      !@project.namespace.members.owners.where.not(id: member.id).exists?
    end
  end
end
