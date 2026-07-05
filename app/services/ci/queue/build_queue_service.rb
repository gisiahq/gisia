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
  module Queue
    class BuildQueueService
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      def new_builds
        strategy.new_builds
      end

      def build_candidates
        candidates =
          if runner.project_type?
            builds_for_project_runner
          elsif runner.group_type?
            builds_for_group_runner
          else
            builds_for_shared_runner
          end

        candidates = builds_for_protected_runner(candidates) if runner.ref_protected?

        # pick builds that does not have other tags than runner's one
        candidates = builds_matching_tag_ids(candidates, runner.tagging_tag_ids)

        # pick builds that have at least one tag
        candidates = builds_with_any_tags(candidates) unless runner.run_untagged?

        candidates
      end

      ##
      # This is overridden in EE
      #
      def builds_for_shared_runner
        strategy.builds_for_shared_runner
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def builds_for_group_runner
        strategy.builds_for_group_runner
      end

      def builds_for_project_runner
        order(new_builds.where(namespace_id: runner.namespace_ids))
      end

      def builds_for_protected_runner(relation)
        relation.ref_protected
      end

      def builds_matching_tag_ids(relation, ids)
        strategy.builds_matching_tag_ids(relation, ids)
      end

      def builds_with_any_tags(relation)
        strategy.builds_with_any_tags(relation)
      end

      def order(relation)
        strategy.order(relation)
      end

      def execute(relation)
        strategy.build_and_partition_ids(relation)
      end

      private

      def strategy
        strong_memoize(:strategy) do
          Queue::PendingBuildsStrategy.new(runner)
        end
      end
    end
  end
end

Ci::Queue::BuildQueueService.prepend_mod_with('Ci::Queue::BuildQueueService')
