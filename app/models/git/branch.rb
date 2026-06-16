# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Git
  class Branch < Base
    include HasPipeline
    include MergeRequests::Refreshable
    include Wisper::Publisher

    delegate :oldrev, :newrev, :ref, to: :change

    def push
      create_pipelines!
      refresh!
      publish_webhook_event
    end

    private

    def publish_webhook_event
      commits = project.repository.commits_between(oldrev, newrev)
      payload = Gitlab::DataBuilder::Push.build(
        project: project,
        user: current_user,
        oldrev: oldrev,
        newrev: newrev,
        ref: ref,
        commits: commits,
        push_options: params[:push_options] || {}
      )

      broadcast(:branch_push, project, payload)
    end
  end
end

