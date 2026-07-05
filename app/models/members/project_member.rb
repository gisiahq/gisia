# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class ProjectMember < Member
  belongs_to :user
  belongs_to :namespace, class_name: 'Namespaces::ProjectNamespace', foreign_key: 'namespace_id'
  has_one :project, through: :namespace

  validate :namespace_must_be_project_namespace
  validate :access_level_not_below_inherited

  scope :with_project, ->(project) { with_namespace project.namespace }
  scope :with_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :with_roles, ->(roles) { where(access_level: roles) }

  private

  def namespace_must_be_project_namespace
    return if namespace.is_a?(Namespaces::ProjectNamespace)

    errors.add(:namespace, _('must be a project namespace'))
  end

  def access_level_not_below_inherited
    return unless namespace.is_a?(Namespaces::ProjectNamespace) && user_id

    inherited = GroupMember.non_request
      .where(namespace_id: namespace.traversal_ids, user_id: user_id)
      .maximum(:access_level)
    return if inherited.nil? || Member.access_level_value(access_level) >= inherited

    errors.add(:access_level, _('cannot be lower than inherited membership (%{level})') % { level: Gitlab::Access.human_access(inherited) })
  end
end

ProjectMember.prepend_mod_with('ProjectMember')
