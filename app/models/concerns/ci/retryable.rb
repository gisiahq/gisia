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
  module Retryable
    extend ActiveSupport::Concern

    def retry!(current_user)
      unless retryable?
        errors.add(:base, 'Job is not retryable')
        return
      end

      new_job = clone(current_user: current_user)
      new_job.save!
      new_job.update_older_statuses_retried!
      pipeline.reset_skipped_jobs(current_user, self)

      ProcessPipelineJob.perform_later(pipeline_id)

      new_job
    end
  end
end
