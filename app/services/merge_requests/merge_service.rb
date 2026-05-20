# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module MergeRequests
  class MergeService
    MergeError = Class.new(StandardError)

    GENERIC_ERROR_MESSAGE = 'An error occurred while merging'

    attr_reader :merge_request, :current_user

    def initialize(merge_request:, current_user:)
      @merge_request = merge_request
      @current_user = current_user
    end

    def execute
      return error('Merge request is not open') unless merge_request.opened?
      return error('No source for merge') if merge_request.diff_head_sha.blank?

      lease = merge_request.merge_exclusive_lease
      return error('Merge request is already being merged') unless lease.try_obtain

      merge_request.in_locked_state do
        commit_sha = perform_merge
        raise MergeError, GENERIC_ERROR_MESSAGE unless commit_sha

        merge_request.update!(
          merge_commit_sha: commit_sha,
          merged_commit_sha: commit_sha,
          merge_user: current_user
        )
        merge_request.mark_as_merged
        merge_request.metrics.update!(merged_by: current_user, merged_at: Time.current)
      end

      MergeRequests::DeleteSourceBranchJob.perform_later(merge_request.id, current_user.id)

      success
    rescue MergeError => e
      merge_request.update(merge_error: e.message)
      error(e.message)
    rescue StandardError => e
      merge_request.update(merge_error: "#{e.class}: #{e.message}")
      error("#{e.class}: #{e.message}")
    ensure
      lease&.cancel
    end

    private

    def perform_merge
      source_sha = merge_request.diff_head_sha
      message = merge_request.default_merge_commit_message(user: current_user)
      raw_repo = merge_request.target_project.repository.raw_repository

      if merge_request.target_project.namespace.namespace_settings&.squash_enabled?
        target_sha = merge_request.target_project.repository.commit(merge_request.target_branch)&.sha
        squash_sha = raw_repo.squash(current_user, start_sha: target_sha, end_sha: source_sha, author: current_user, message: message)
        raw_repo.ff_merge(current_user, source_sha: squash_sha, target_branch: merge_request.target_branch)
        squash_sha
      else
        merge_request.target_project.repository.merge(current_user, source_sha, merge_request, message)
      end
    end

    def success
      { status: :success }
    end

    def error(message)
      { status: :error, message: message }
    end
  end
end
