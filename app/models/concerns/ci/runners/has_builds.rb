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
  module Runners
    module HasBuilds
      extend ActiveSupport::Concern

      included do
        attr_accessor :runner, :runner_manager
      end

      TEMPORARY_LOCK_TIMEOUT = 3.seconds
      MAX_QUEUE_DEPTH = 45

      Result = Struct.new(:build, :build_json, :build_presented, :valid?)

      class_methods do
        def assign_to(runner, runner_manager, runner_params)
          ins = new(runner: runner, runner_manager: runner_manager)
          ins.assign_builds(runner_params)
        end
      end

      def assign_builds(runner_params)
        process_queue(runner_params)
      end

      private

      def process_queue(params)
        valid = true
        depth = 0

        each_build do |build|
          depth += 1

          if depth > MAX_QUEUE_DEPTH
            valid = false
            break
          end

          unless acquire_temporary_lock(build.id)
            valid = false
            next
          end

          result = process_build(build, params)
          next unless result

          return result if result.valid?

          valid = false
        end

        Result.new(nil, nil, nil, valid)
      end

      def each_build
        build_queue_service.build_candidates.each do |build|
          yield Ci::Build.find_by!(id: build.build_id)
        end
      end

      def build_queue_service
        strong_memoize(:build_queue_service) do
          Queue::BuildQueueService.new(runner)
        end
      end

      def remove_from_queue!(build)
        Result.new(nil, nil, nil, false) if remove!(build)
      end

      def runner_matched?(build)
        runner.matches_build?(build)
      end

      def process_build(build, params)
        return remove_from_queue!(build) unless build.pending?

        # Make sure that composite identity is propagated to `PipelineProcessWorker`
        # when the build's status change.
        ::Gitlab::Auth::Identity.link_from_job(build)

        # In case when 2 runners try to assign the same build, second runner will be declined
        # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
        present_build_with_instrumentation!(build) if assign_runner_with_instrumentation!(build, params)
      rescue ActiveRecord::StaleObjectError
        # We are looping to find another build that is not conflicting
        # It also indicates that this build can be picked and passed to runner.
        # If we don't do it, basically a bunch of runners would be competing for a build
        # and thus we will generate a lot of 409. This will increase
        # the number of generated requests, also will reduce significantly
        # how many builds can be picked by runner in a unit of time.
        # In case we hit the concurrency-access lock,
        # we still have to return 409 in the end,
        # to make sure that this is properly handled by runner.

        Result.new(nil, nil, nil, false)
      rescue StateMachines::InvalidTransition
        Result.new(nil, nil, nil, false)
      end

      def assign_runner_with_instrumentation!(build, params)
        assign_runner!(build, params)
      end

      def assign_runner!(build, params)
        build.runner_id = runner.id
        build.runner_session_attributes = params[:session] if params[:session].present?

        # Todo,
        failure_reason = false

        if failure_reason
          build.drop!(failure_reason)
        else
          build.run!

          build.runner_manager = runner_manager if runner_manager
        end

        !failure_reason
      end

      def present_build_with_instrumentation!(build)
        present_build!(build)
      end

      # Force variables evaluation to occur now
      def present_build!(build)
        # We need to use the presenter here because Gitaly calls in the presenter
        # may fail, and we need to ensure the response has been generated.
        presented_build = ::Ci::BuildRunnerPresenter.new(build) # -- old code

        Result.new(build, presented_build.to_json, presented_build, true)
      end

      def acquire_temporary_lock(build_id)
        return true if Feature.disabled?(:ci_register_job_temporary_lock, runner, type: :ops)

        key = "build/register/#{build_id}"

        Gitlab::ExclusiveLease
          .new(key, timeout: TEMPORARY_LOCK_TIMEOUT.to_i)
          .try_obtain
      end
    end
  end
end

