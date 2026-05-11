# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authz
  class Resource
    include Authz::Concerns::YamlPermission

    BASE_PATH = 'config/authz/permissions'

    class << self
      def config_path
        Rails.root.join(BASE_PATH, '**/.metadata.yml')
      end

      private

      def resource_identifier(_, file_path)
        File.basename(File.dirname(file_path)).to_sym
      end
    end

    def name
      File.basename(File.dirname(source_file))
    end

    def resource_name
      definition[:name] || name.titlecase
    end

    def feature_category
      definition[:feature_category]
    end
  end
end
