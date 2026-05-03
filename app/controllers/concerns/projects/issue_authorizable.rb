# frozen_string_literal: true

module Projects
  module IssueAuthorizable
    extend ActiveSupport::Concern

    private

    def authorize_read_issues!
      authorization_denied! unless can?(current_user,:read_issue, @project)
    end

    def authorize_create_issue!
      authorization_denied! unless can?(current_user,:create_issue, @project)
    end

    def authorize_read_issuable!
      authorization_denied! unless can?(current_user,:read_issue, issuable_resource)
    end

    def authorize_update_issuable!
      authorization_denied! unless can?(current_user,:update_issue, issuable_resource)
    end

    def authorize_destroy_issuable!
      authorization_denied! unless can?(current_user,:destroy_issue, issuable_resource)
    end

    def authorization_denied!
      forbidden!
    end
  end
end
