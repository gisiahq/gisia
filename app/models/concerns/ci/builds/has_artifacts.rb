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
    module HasArtifacts
      extend ActiveSupport::Concern

      included do
        scope :with_downloadable_artifacts, -> { where_exists(Ci::JobArtifact.scoped_build.downloadable) }
      end

      def artifacts_file
        job_artifacts_archive&.file
      end

      def artifacts_size
        job_artifacts_archive&.size
      end

      def artifacts_metadata
        job_artifacts_metadata&.file
      end

      def artifacts?
        !artifacts_expired? && artifacts_file&.exists?
      end

      def locked_artifacts?
        pipeline.artifacts_locked? && artifacts_file&.exists?
      end

      def available_artifacts?
        (!artifacts_expired? || pipeline.artifacts_locked?) && job_artifacts_archive&.exists?
      end

      def artifacts_metadata?
        artifacts? && artifacts_metadata&.exists?
      end

      def artifacts_expired?
        artifacts_expire_at&.past?
      end

      def keep_artifacts!
        update(artifacts_expire_at: nil)
        job_artifacts.update_all(expire_at: nil)
      end

      def artifact_access_setting_in_config
        artifacts_public = options.dig(:artifacts, :public)
        artifacts_access = options.dig(:artifacts, :access)&.to_s

        if artifacts_public.present? && artifacts_access.present?
          raise ArgumentError, 'artifacts:public and artifacts:access are mutually exclusive'
        end

        return :public     if artifacts_public == true || artifacts_access == 'all'
        return :private    if artifacts_public == false || artifacts_access == 'developer'
        return :maintainer if artifacts_access == 'maintainer'
        return :none       if artifacts_access == 'none'

        :public
      end

      def artifacts_metadata_entry(path, **options)
        artifacts_metadata.open do |metadata_stream|
          metadata = Gitlab::Ci::Build::Artifacts::Metadata.new(
            metadata_stream,
            path,
            **options)

          metadata.to_entry
        end
      end
    end
  end
end
