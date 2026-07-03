# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Groups
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

    def assignable_access_levels
      Gitlab::Access.sym_options_with_owner.select { |_, level| can_assign_level?(level) }
    end

    def actor_access_level
      @actor_access_level ||= current_user.max_member_access_for_namespace(@namespace)
    end

    def normalize_access_level(level)
      Member.access_level_value(level)
    end

    def last_owner?(member)
      return false unless member.owner?

      !GroupMember.non_request.owners
        .where(namespace_id: @namespace.traversal_ids)
        .where.not(id: member.id)
        .exists?
    end
  end
end
