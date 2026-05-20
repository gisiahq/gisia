# frozen_string_literal: true

module MergeRequests
  class DeleteSourceBranchJob < ApplicationJob
    queue_as :default

    def perform(merge_request_id, user_id)
      merge_request = MergeRequest.find_by(id: merge_request_id)
      return unless merge_request
      return unless merge_request.merged?
      settings = merge_request.target_project.namespace.namespace_settings
      return unless settings.remove_source_branch_after_merge?

      user = User.find_by(id: user_id)
      return unless user

      merge_request.target_project.repository.rm_branch(user, merge_request.source_branch)
    end
  end
end
