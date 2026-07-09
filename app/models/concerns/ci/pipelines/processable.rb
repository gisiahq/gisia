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
    module Processable
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      DEFAULT_LEASE_TIMEOUT = 1.minute
      BATCH_SIZE = 20

      def process!
        return unless needs_processing?

        ensure_persistent_ref

        @collection = Ci::PipelineJobStatusCollection.new(self)
        success = try_obtain_lease { process }

        if success
          new_alive_jobs.group_by(&:user).each do |user, jobs|
            reset_skipped_jobs(user, jobs)
          end

          ProcessPipelineJob.perform_later(id) if needs_processing?
        end

        success
      end

      def needs_processing?
        statuses.where(processed: [false, nil]).latest.exists?
      end

      private

      def process
        update_stages!
        update_pipeline!
        update_jobs_processed!

        true
      end

      def update_stages!
        stages.ordered.each { |stage| update_stage!(stage) }
      end

      def update_stage!(stage)
        sorted_update_stage!(stage)
        status = @collection.status_of_stage(stage.position)
        stage.set_status(status)
      end

      def sorted_update_stage!(stage)
        ordered_jobs(stage).each { |job| update_job!(job) }
      end

      def ordered_jobs(stage)
        jobs = load_jobs_in_batches(stage)
        sorted_job_names = sort_jobs(jobs).each_with_index.to_h
        jobs.sort_by { |job| sorted_job_names.fetch(job.name) }
      end

      def load_jobs_in_batches(stage)
        @collection
          .created_job_ids_in_stage(stage.position)
          .in_groups_of(BATCH_SIZE, false)
          .each_with_object([]) do |ids, jobs|
            jobs.concat(load_jobs(ids))
          end
      end

      def load_jobs(ids)
          current_processable_jobs
          .id_in(ids)
          .with_project_preload
          .created
          .ordered_by_stage
          .select_with_aggregated_needs(project)
      end

      def sort_jobs(jobs)
        Gitlab::Ci::YamlProcessor::Dag.order( # -- this is not ActiveRecord
          jobs.to_h do |job|
            [job.name, job.aggregated_needs_names.to_a]
          end
        )
      end

      def update_pipeline!
        set_status(@collection.status_of_all)
      end

      def update_jobs_processed!
        processing = @collection.processing_jobs
        processing.each_slice(BATCH_SIZE) do |slice|
          all_jobs.match_id_and_lock_version(slice)
                  .update_as_processed!
        end
      end

      def update_job!(job)
        previous_status = status_of_previous_jobs(job)
        # We do not continue to process the job if the previous status is not completed
        return unless Ci::HasStatus::COMPLETED_STATUSES.include?(previous_status)

        Gitlab::OptimisticLocking.retry_lock(job, name: 'atomic_processing_update_job') do |subject|
          subject.prosess!(previous_status)

          # update internal representation of job
          # to make the status change of job to be taken into account during further processing
          @collection.set_job_status(job.id, job.status, job.lock_version)
        end
      end

      def status_of_previous_jobs(job)
        if job.scheduling_type_dag?
          status_of_previous_jobs_dag(job)
        else
          # job uses Stages, get status of prior stage
          @collection.status_of_jobs_prior_to_stage(job.stage_idx.to_i)
        end
      end

      def status_of_previous_jobs_dag(job)
        # job uses DAG, get status of all dependent needs
        @collection.status_of_jobs(job.aggregated_needs_names.to_a)
      end

      # Gets the jobs that changed from stopped to alive status since the initial status collection
      # was evaluated. We determine this by checking if their current status is no longer stopped.
      def new_alive_jobs
        initial_stopped_job_names = @collection.stopped_job_names

        return [] if initial_stopped_job_names.empty?

        new_collection = Ci::PipelineJobStatusCollection.new(self)
        new_alive_job_names = initial_stopped_job_names - new_collection.stopped_job_names

        return [] if new_alive_job_names.empty?

        current_jobs
          .by_name(new_alive_job_names)
          .preload(:user)
          .to_a
      end

      def lease_key
        "#{super}::pipeline_id:#{id}"
      end

      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end

      def lease_taken_log_level
        :info
      end
    end
  end
end
