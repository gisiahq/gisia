# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Gitlab
  class OptimisticLocking # rubocop:disable Gitlab/NamespacedClass -- platform layer
    MAX_RETRIES = 100

    class << self
      def retry_lock_with_transaction(subject, max_retries = MAX_RETRIES, name:, &block)
        # prevent scope override, see https://gitlab.com/gitlab-org/gitlab/-/issues/391186
        klass = subject.is_a?(ActiveRecord::Relation) ? subject.klass : subject.class

        retry_lock(subject, max_retries, name: name) do |inner_subject|
          klass.transaction do
            yield(inner_subject)
          end
        end
      end

      def retry_lock(subject, max_retries = MAX_RETRIES, name:, &block)
        start_time = ::Gitlab::Metrics::System.monotonic_time
        retry_attempts = 0

        begin
          yield(subject)
        rescue ActiveRecord::StaleObjectError
          raise unless retry_attempts < max_retries

          subject.reset

          retry_attempts += 1
          retry
        ensure
          # Todo,
        end
      end
    end
  end
end

