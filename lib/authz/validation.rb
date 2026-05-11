# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authz
  class Validation
    PERMISSION_NAME_REGEX = /\A_?[a-z]+_[a-z_]+[a-z]\z/

    COMMON_ACTIONS = {
      create: 'Creates a new resource',
      read: 'Views or retrieves a resource',
      update: 'Modifies an existing resource',
      delete: 'Removes a resource'
    }.freeze

    DISALLOWED_ACTIONS = {
      admin: 'a granular action',
      change: 'update',
      destroy: 'delete',
      edit: 'update',
      list: 'read',
      manage: 'a granular action',
      modify: 'update',
      set: 'update',
      view: 'read',
      write: 'a granular action'
    }.freeze
  end
end
