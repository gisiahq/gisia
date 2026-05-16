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
  module Pipelines
    module HasPersistentRef
      TIMEOUT = 1.hour
      CACHE_KEY = 'pipeline:%{id}:create_persistent_ref_service'

      def persistent_ref
        @persistent_ref ||= PersistentRef.new(pipeline: self)
      end

      def ensure_persistent_ref
        Rails.cache.fetch(pipeline_persistent_ref_cache_key, expires_in: TIMEOUT) do
          next true if persistent_ref.exist?
          next true if persistent_ref.create

          drop!(:pipeline_ref_creation_failure)
          false
        end
      end

      private

      def pipeline_persistent_ref_cache_key
        format(CACHE_KEY, id: id)
      end
    end
  end
end

