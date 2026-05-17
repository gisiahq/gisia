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
  module HasCommitBuildStatus
    extend ActiveSupport::Concern

    included do
      state_machine :status do
        event :process do
          transition %i[skipped manual] => :created
        end

        event :enqueue do
          # A CommitStatus will never have prerequisites, but this event
          # is shared by Ci::Build, which cannot progress unless prerequisites
          # are satisfied.
          transition %i[created skipped manual scheduled] => :pending, if: :all_met_to_become_pending?
        end

        event :run do
          transition pending: :running
        end

        event :skip do
          transition %i[created waiting_for_resource preparing pending] => :skipped
        end

        event :drop do
          transition canceling: :canceled # runner returns success/failed
          transition %i[
            created
            waiting_for_resource
            preparing
            waiting_for_callback
            pending
            running
            manual
            scheduled
          ] => :failed
        end

        event :succeed do
          transition canceling: :canceled # runner returns success/failed
          transition %i[created waiting_for_resource preparing waiting_for_callback pending running] => :success
        end

        event :cancel do
          transition running: :canceling, if: :supports_canceling?
          transition ::Ci::HasStatus::CANCELABLE_STATUSES.map(&:to_sym) + [:manual] => :canceled
        end

        event :force_cancel do
          transition canceling: :canceled, if: :supports_force_cancel?
        end

        before_transition %i[
          created
          waiting_for_resource
          preparing
          skipped
          manual
          scheduled
        ] => :pending do |commit_status|
          commit_status.queued_at = Time.current
        end

        before_transition %i[created preparing pending] => :running do |commit_status|
          commit_status.started_at = Time.current
        end

        before_transition any => %i[success failed canceled] do |commit_status|
          commit_status.finished_at = Time.current
        end

        before_transition any => :failed do |commit_status, transition|
          reason = ::Gitlab::Ci::Build::Status::Reason
                   .fabricate(commit_status, transition.args.first)

          commit_status.failure_reason = reason.failure_reason_enum
          commit_status.allow_failure = true if reason.force_allow_failure?
          # Windows exit codes can reach a max value of 32-bit unsigned integer
          # We only allow a smallint for exit_code in the db, hence the added limit of 32767
          commit_status.exit_code = reason.exit_code
        end

        before_transition %i[skipped manual] => :created do |commit_status, transition|
          transition.args.first.try do |user|
            commit_status.user = user
          end
        end

        after_transition do |commit_status, transition|
          next if transition.loopback?
          next if commit_status.processed?
          next unless commit_status.project

          last_arg = transition.args.last
          transition_options = last_arg.is_a?(Hash) && last_arg.extractable_options? ? last_arg : {}

          commit_status.run_after_commit do
            ProcessPipelineJob.perform_later(pipeline_id) unless transition_options[:skip_pipeline_processing]

            # expire_etag_cache!
          end
        end

        after_transition any => :failed do |commit_status|
          commit_status.run_after_commit do
            # ::Gitlab::Ci::Pipeline::Metrics.job_failure_reason_counter.increment(reason: commit_status.failure_reason)
          end
        end
      end
    end

    def supports_canceling?
      cancel_gracefully?
    end

    def cancel_gracefully?
      return false unless respond_to?(:runner_manager)

      !!runner_manager&.supports_after_script_on_cancel?
    end
  end
end
