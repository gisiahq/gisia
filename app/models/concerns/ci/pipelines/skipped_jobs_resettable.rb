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
    module SkippedJobsResettable
      extend ActiveSupport::Concern

      def reset_skipped_jobs(current_user, processables)
        @current_user = current_user
        @processables = Array.wrap(processables)

        process_subsequent_jobs
      end

      private

      attr_reader :current_user

      def process_subsequent_jobs
        dependent_jobs.each do |job|
          reset_job(job)
        end
      end

      def dependent_jobs
        ordered_by_dag(
          processables
            .from_union(needs_dependent_jobs, stage_dependent_jobs)
            .skipped
            .ordered_by_stage
            .preload(:needs)
        )
      end

      def reset_job(job)
        Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_requeue_job') do |job|
          job.process(current_user)
        end
      end

      def stage_dependent_jobs
        # Get all jobs after the earliest stage of the inputted jobs
        min_stage_idx = @processables.map(&:stage_idx).min
        processables.after_stage(min_stage_idx)
      end

      def needs_dependent_jobs
        # We must include the hierarchy base here because @processables may include both a parent job
        # and its dependents, and we do not want to exclude those dependents from being processed.
        ::Gitlab::Ci::ProcessableObjectHierarchy.new(
          # Todo,
          ::Ci::Processable.where(id: @processables.map(&:id))
        ).base_and_descendants
      end

      def ordered_by_dag(jobs)
        sorted_job_names = sort_jobs(jobs).each_with_index.to_h

        jobs.group_by(&:stage_idx).flat_map do |_, stage_jobs|
          stage_jobs.sort_by { |job| sorted_job_names.fetch(job.name) }
        end
      end

      def sort_jobs(jobs)
        Gitlab::Ci::YamlProcessor::Dag.order(
          jobs.to_h do |job|
            [job.name, job.needs.map(&:name)]
          end
        )
      end
    end
  end
end
