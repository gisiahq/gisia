# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class ProtectedBranch < ProtectedRef
  scope :force_push, -> { where(allow_force_push: true) }
  scope :push, -> { where(allow_push: true) }
  scope :merge_to, -> { where(allow_merge_to: true) }

  def self.allow_force_push?(project, ref_name)
    project.protected_branches.force_push.any? { |pb| pb.matches?(ref_name) }
  end

  def self.protected?(project, name)
    return false if name.blank?
    return true if project.empty_repo?

    matches?(name, protected_refs: project.protected_branches)
  end

  ACTION_SCOPE_MAP = { push: :push, merge: :merge_to }.freeze

  def self.with_access_levels(action)
    scope_name = ACTION_SCOPE_MAP[action]
    scope_name ? public_send(scope_name) : all
  end

  def self.protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
    if project.empty_repo?
      max_access = user.max_access(project)

      # Admins are always allowed to create the default branch
      return true if user.admin? || user.can?(:admin_project, project)

      return false
    end

    super
  end
end
