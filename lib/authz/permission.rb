# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authz
  class Permission
    include Authz::Concerns::YamlPermission

    BASE_PATH = 'config/authz/permissions'

    class << self
      def config_path
        Rails.root.join(BASE_PATH, '**/[_a-z]?*.yml')
      end
    end
  end
end
