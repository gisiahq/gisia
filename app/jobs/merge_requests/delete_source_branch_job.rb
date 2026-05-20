# frozen_string_literal: true

module MergeRequests
  class DeleteSourceBranchJob < ApplicationJob
    queue_as :default

    def perform(merge_request_id, user_id)
      user = User.find_by(id: user_id)
      return unless user

      merge_request = MergeRequest.find_by(id: merge_request_id)
      return unless merge_request
      return unless merge_request.merged?

      return unless merge_request.target_project.namespace.namespace_settings&.remove_source_branch_after_merge?
      return unless merge_request.can_remove_source_branch?(user)

      merge_request.target_project.repository.delete_branch(merge_request.source_branch)
    end
  end
end
