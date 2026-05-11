# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authz
  module PermissionGroups
    class Internal < Base
      BASE_PATH = 'config/authz/permission_groups/internal'

      def self.config_path
        Rails.root.join(BASE_PATH, '**/*.yml')
      end

      def name
        relative_path = source_file.sub(path_regex, '')
        prefix = File.dirname(relative_path).tr('/', ':')
        name = File.basename(relative_path, File.extname(relative_path))

        "#{prefix}:#{name}"
      end
      strong_memoize_attr :name

      private

      def path_regex
        @path_regex ||= %r{.*#{BASE_PATH}/?}
      end
    end
  end
end
