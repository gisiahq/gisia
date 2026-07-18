# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Namespaces
  class GroupNamespace < Namespace
    has_one :group, inverse_of: :namespace, foreign_key: :namespace_id
    has_many :members, foreign_key: :namespace_id, dependent: :destroy, class_name: 'GroupMember'
    has_many :variables, class_name: 'Ci::Variable', foreign_key: :namespace_id, dependent: :destroy

    def self.sti_name
      'Group'
    end

    def self.polymorphic_name
      'Namespaces::GroupNamespace'
    end

    def pin_class
      Namespaces::GroupNamespacePin
    end

    def member?(user, min_access_level = Gitlab::Access::GUEST)
      return false unless user

      max_member_access_for_user(user) >= min_access_level
    end

    def max_member_access_for_user(user)
      user.max_member_access_for_namespace(self)
    end

    def member_of_self_or_descendant?(user)
      return false unless user

      members_with_descendants.exists?(user_id: user)
    end

    def members_with_descendants
      GroupMember.non_request
        .where(namespace_id: self_and_descendant_ids(skope: Namespaces::GroupNamespace))
    end
  end
end
