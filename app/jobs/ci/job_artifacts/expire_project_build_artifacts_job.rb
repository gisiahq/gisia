# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Ci
  module JobArtifacts
    class ExpireProjectBuildArtifactsJob < ApplicationJob
      queue_as :default

      def perform(project_id)
        return unless Project.exists?(project_id)

        Ci::JobArtifacts::ExpireProjectBuildArtifactsService.new(project_id, Time.current).execute
      end
    end
  end
end
