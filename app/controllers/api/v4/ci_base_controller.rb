# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module API
  module V4
    class CiBaseController < ::API::V4::BaseController
      include Gitlab::Utils::StrongMemoize
      include API::V4::CiBaseHelper

      private

      def authenticate_runner!(ensure_runner_manager: true, creation_state: nil)
        return forbidden! unless current_runner

        current_runner.heartbeat(creation_state: creation_state) if ensure_runner_manager
        return unless ensure_runner_manager

        runner_details = runner_details_from_request
        current_runner_manager&.heartbeat(runner_details)
      end

      def authenticate_job_with_token!; end

      def token
        params.require(:token)
      end

      def current_runner
        strong_memoize(:current_runner) do
          ::Ci::Runner.find_by_token(token.to_s)
        end
      end

      def runner_details_from_request
        return runner_ip unless params['info'].present?

        detail_params
          .merge(system_id_from_request)
          .merge(runner_config_from_request)
          .merge(runner_ip)
          .merge(runner_features_from_request).permit!.to_h
      end

      def system_id_from_request
        return { system_id: params[:system_id] } if params.include?(:system_id)

        {}
      end

      def runner_config_from_request
        { config: attributes_for_keys(%w[gpus], params.dig('info', 'config')) }
      end

      def runner_ip
        { ip_address: request.remote_ip }
      end

      def runner_features_from_request
        { runtime_features: params.dig('info', 'features') }.compact
      end

      def detail_params
        params.permit(info: %i[name version revision platform architecture executor])
      end

      def current_runner_manager
        strong_memoize(:current_runner_manager) do
          system_xid = params.fetch(:system_id, LEGACY_SYSTEM_XID)
          current_runner&.ensure_manager(system_xid)
        end
      end

      # This method returns a Job or halts the request with 403 status and message
      def authenticate_job!
        # Return 403 unless current_job exists
        return forbidden!('Job not found') unless current_job

        begin
          @job = job_from_token

          forbidden!('Invalid job token') unless @job
        rescue ::Ci::AuthJobFinder::DeletedProjectError
          forbidden!('Project has been deleted!')
        rescue ::Ci::AuthJobFinder::ErasedJobError
          forbidden!('Job has been erased!')
        rescue ::Ci::AuthJobFinder::NotRunningJobError
          # current_job exists but job is not running; provide explicit forbidden message
          job_forbidden!(current_job, 'Job is not processing on runner')
        end
      end

      def runner_heartbeat
        # Propagate composite identity to PipelineProcessWorker
        ::Gitlab::Auth::Identity.link_from_job(@job)

        @job.runner&.heartbeat
        @job.runner_manager&.heartbeat(runner_ip)
      end

      def job_forbidden!(job, reason)
        response.set_header('Job-Status', job.status)
        render json: { message: reason }, status: :forbidden
      end
    end
  end
end

