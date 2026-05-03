# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module API
  module V4
    module ProjectFindable
      extend ActiveSupport::Concern

      INTEGER_ID_REGEX = /^-?\d+$/

      private

      def find_project(id)
        return unless id

        projects = find_project_scopes

        if id.is_a?(Integer) || id =~ INTEGER_ID_REGEX
          projects.find_by(id: id)
        elsif id.include?("/")
          projects.find_by_full_path(id)
        end
      end

      def find_project_scopes
        Project.all
      end

      def find_project!
        id = params[:project_id] || params[:id]
        @project = find_project(id)
        return not_found! unless @project
        return not_found! unless @project.public? || current_user&.can?(:read_project, @project)
      end
    end
  end
end
