# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class GroupMember < Member
  include FromUnion
  include CreatedAtFilterable

  belongs_to :namespace, class_name: 'Namespaces::GroupNamespace', foreign_key: 'namespace_id'
  has_one :group, through: :namespace

  validate :namespace_must_be_group_namespace

  scope :of_groups, ->(groups) { where(source_id: groups) }
  scope :with_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :count_users_by_namespace_id, -> { group(:namespace_id).count }

  private

  def namespace_must_be_group_namespace
    return if namespace.is_a?(Namespaces::GroupNamespace)

    errors.add(:namespace, _('must be a group namespace'))
  end
end
