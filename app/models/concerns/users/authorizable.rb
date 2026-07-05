# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Users
  module Authorizable
    extend ActiveSupport::Concern

    def max_access(project)
      namespace_ids = project.namespace.traversal_ids

      [
        project_members.with_project(project).maximum(:access_level),
        group_members.where(namespace_id: namespace_ids).maximum(:access_level)
      ].compact.max || Gitlab::Access::NO_ACCESS
    end
  end
end
