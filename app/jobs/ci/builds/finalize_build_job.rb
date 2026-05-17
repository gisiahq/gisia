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
  module Builds
    class FinalizeBuildJob < ApplicationJob

      ARCHIVE_TRACES_IN = 2.minutes.freeze

      def perform(build_id)
        return unless build = Ci::Build.find_by_id(build_id)
        return unless build.project
        return if build.project.pending_delete?

        process_build(build)
      end

      private

      def process_build(build)
        Gitlab::OptimisticLocking.retry_lock(build, name: 'finalize_build_remove_token') do |b|
          b.remove_token!
        end
        Ci::Builds::ArchiveTraceJob.set(wait: ARCHIVE_TRACES_IN).perform_later(build.id)
      end
    end
  end
end

