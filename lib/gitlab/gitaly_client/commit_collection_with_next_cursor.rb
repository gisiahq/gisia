# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module GitalyClient
    class CommitCollectionWithNextCursor < SimpleDelegator
      def initialize(response, repository)
        commits = response.flat_map do |message|
          cursor = message.pagination_cursor&.next_cursor
          @next_cursor = cursor if cursor.present?

          message.commits.map do |gitaly_commit|
            Gitlab::Git::Commit.new(repository, gitaly_commit)
          end
        end

        super(commits)
      end

      attr_reader :next_cursor
    end
  end
end
