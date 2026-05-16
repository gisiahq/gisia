# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module API::V4::CiBaseHelper
  include Gitlab::Utils::StrongMemoize

  JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'
  JOB_TOKEN_PARAM = :token
  LEGACY_SYSTEM_XID = '<legacy>'

  def current_job
    id = params[:id]

    strong_memoize(:current_job) do
      ::Ci::Build.find_by_id(id)
    end
  end

  # The token used by runner to authenticate a request.
  # In most cases, the runner uses the token belonging to the requested job.
  # However, when requesting for job artifacts, the runner would use
  # the token that belongs to downstream jobs that depend on the job that owns
  # the artifacts.
  def job_token
    # Todo, check the env
    @job_token ||= (params[JOB_TOKEN_PARAM] || request.env[JOB_TOKEN_HEADER]).to_s
  end

  def attributes_for_keys(keys, custom_params = nil)
    params_hash = custom_params || params
    attrs = {}
    keys.each do |key|
      if params_hash[key].present? || (params_hash.key?(key) && params_hash[key] == false)
        attrs[key] = params_hash[key]
      end
    end
    permitted_attrs = ActionController::Parameters.new(attrs).permit!
    permitted_attrs.to_h
  end

  def job_from_token
    # Uses the Ci::AuthJobFinder, which we want to use
    # as the sole centralized job token authentication service.
    #
    # If the token does not link to the URL-specified job,
    # return a generic auth error with no build details.
    return unless current_job
    return unless current_job == ::Ci::AuthJobFinder.new(token: job_token).execute!

    current_job
  end

  def authenticate_job_via_dependent_job!
    forbidden! unless current_job

    consuming_job = ::Ci::AuthJobFinder.new(token: job_token).execute
    forbidden! unless consuming_job
    forbidden! unless can?(consuming_job.user, :read_build, current_job.project)
  rescue ::Ci::AuthJobFinder::DeletedProjectError
    forbidden!('Project has been deleted!')
  rescue ::Ci::AuthJobFinder::ErasedJobError
    forbidden!('Job has been erased!')
  end
end

