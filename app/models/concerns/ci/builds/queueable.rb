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
    module Queueable
      extend ActiveSupport::Concern
      extend MethodOverrideGuard

      ##
      # Add a build to the pending builds queue
      #
      def push(build, transition)
        raise InvalidQueueTransition unless transition.to == 'pending'

        transition.within_transaction do
          result = build.create_queuing_entry!

          result.rows.dig(0, 0) unless result.empty?
        end
      end

      ##
      # Remove a build from the pending builds queue
      #
      def pop(build, transition)
        raise InvalidQueueTransition unless transition.from == 'pending'

        transition.within_transaction { remove!(build) }
      end

      ##
      # Add runner build tracking entry (used for queuing and for runner fleet dashboard).
      #
      def track(build, transition)
        return if build.runner.nil?

        raise InvalidQueueTransition unless transition.to == 'running'

        transition.within_transaction do
          result = ::Ci::RunningBuild.upsert_build!(build)

          result.rows.dig(0, 0) unless result.empty?
        end
      end

      ##
      # Remove a runtime build tracking entry for a runner build (used for queuing and for runner fleet dashboard).
      #
      def untrack(build, transition)
        return if build.runner.nil?

        raise InvalidQueueTransition unless transition.from == 'running'

        transition.within_transaction do
          removed = build.all_runtime_metadata.delete_all

          build.id if removed > 0
        end
      end

      ##
      # Unblock runners associated with the build's project
      #
      def tick(build)
        runners = build.project.all_available_runners.with_recent_runner_queue.with_tags

        runners.each do |runner|
          runner.pick_build!(build)
        end
      end

      ##
      # Force remove build from the queue, without checking a transition state
      #
      def remove!(build)
        removed = build.all_queuing_entries.delete_all

        return unless removed > 0

        build.id
      end
    end
  end
end

