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
  module HasBuildStatus
    extend ActiveSupport::Concern

    included do
      state_machine :status do
        event :enqueue do
          transition %i[created skipped manual scheduled] => :preparing, if: :any_unmet_prerequisites?
        end

        event :enqueue_scheduled do
          transition scheduled: :preparing, if: :any_unmet_prerequisites?
          transition scheduled: :pending
        end

        event :enqueue_preparing do
          transition preparing: :pending
        end

        event :actionize do
          transition created: :manual
        end

        event :schedule do
          transition created: :scheduled
        end

        event :unschedule do
          transition scheduled: :manual
        end

        before_transition on: :enqueue_scheduled do |build|
          build.scheduled_at.nil? || build.scheduled_at.past? # If false is returned, it stops the transition
        end

        before_transition scheduled: any do |build|
          build.scheduled_at = nil
        end

        before_transition created: :scheduled do |build|
          build.scheduled_at = build.options_scheduled_at
        end

        before_transition on: :enqueue_preparing do |build|
          !build.any_unmet_prerequisites? # If false is returned, it stops the transition
        end

        before_transition any => [:pending] do |build|
          build.ensure_token
          true
        end

        after_transition created: :scheduled do |build|
          build.run_after_commit do
            # Ci::BuildScheduleWorker.perform_at(build.scheduled_at, build.id)
          end
        end

        after_transition any => [:preparing] do |build|
          build.run_after_commit do
            # Ci::BuildPrepareWorker.perform_async(id)
          end
        end

        after_transition any => [:pending] do |build, transition|
          build.push(build, transition)

          # build.run_after_commit do
          #   BuildQueueWorker.perform_async(id)
          #   build.execute_hooks
          # end
        end

        after_transition pending: any do |build, transition|
          build.pop(build, transition)
        end

        after_transition any => [:running] do |build, transition|
          build.track(build, transition)
        end

        after_transition running: any do |build, transition|
          build.untrack(build, transition)

          Ci::BuildRunnerSession.where(build: build).delete_all
        end

        after_transition pending: :running do |build|
          build.update_timeout_state
        end

        after_transition pending: :running do |build|
          build.run_after_commit do
            build.ensure_persistent_ref
          end
        end

        after_transition any => %i[success failed canceled] do |build|
          build.run_after_commit do
            build.run_status_commit_hooks!

            Ci::Builds::FinalizeBuildJob.perform_later(id)
          end
        end

        after_transition any => [:success] do |build|
          build.run_after_commit do
            # PagesWorker.perform_async(:deploy, id) if build.pages_generator?
          end
        end
      end
    end
  end
end
