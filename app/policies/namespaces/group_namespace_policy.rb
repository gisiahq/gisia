# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Namespaces::GroupNamespacePolicy < BasePolicy
  condition(:group_maintainer) do
    @user.present? && GroupMember.non_request
      .with_user(@user)
      .with_at_least_access_level(Accessible::MAINTAINER)
      .where(namespace_id: @subject.traversal_ids)
      .exists?
  end

  condition(:group_owner) do
    @user.present? && GroupMember.non_request
      .with_user(@user)
      .with_at_least_access_level(Accessible::OWNER)
      .where(namespace_id: @subject.traversal_ids)
      .exists?
  end

  rule { admin | group_maintainer }.enable :admin_namespace
  rule { admin | group_owner }.enable :remove_namespace
  rule { admin | group_maintainer }.enable :create_projects
  rule { admin | group_maintainer }.enable :create_subgroup
end
