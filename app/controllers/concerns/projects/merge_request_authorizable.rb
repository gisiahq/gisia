# frozen_string_literal: true

module Projects
  module MergeRequestAuthorizable
    extend ActiveSupport::Concern

    private

    def authorize_read_merge_requests!
      forbidden! unless can?(current_user, :read_merge_request, @project)
    end

    def authorize_create_merge_request!
      forbidden! unless can?(current_user, :create_merge_request_in, @project) &&
                        can?(current_user, :create_merge_request_from, @project)
    end

    def authorize_read_merge_request!
      forbidden! unless can?(current_user, :read_merge_request, @merge_request)
    end

    def authorize_update_merge_request!
      forbidden! unless can?(current_user, :update_merge_request, @merge_request)
    end

    def authorize_destroy_merge_request!
      forbidden! unless can?(current_user, :destroy_merge_request, @merge_request)
    end
  end
end
