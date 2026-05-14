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
  module Pipelines
    module HasRepositoryPaths
      extend ActiveSupport::Concern

      def branch_updated?
        strong_memoize(:branch_updated) do
          push_details.branch_updated?
        end
      end

      def modified_paths_since(compare_to_sha)
        strong_memoize_with(:modified_paths_since, compare_to_sha) do
          project.repository.diff_stats(project.repository.merge_base(compare_to_sha, sha), sha).paths
        end
      end

      def changed_paths
        strong_memoize(:changed_paths) do
          if merge_request?
            merge_request.changed_paths
          elsif branch_updated?
            push_details.changed_paths
          end
        end
      end

      def all_worktree_paths
        strong_memoize(:all_worktree_paths) do
          project.repository.ls_files(sha)
        end
      end

      def top_level_worktree_paths
        strong_memoize(:top_level_worktree_paths) do
          project.repository.tree(sha).blobs.map(&:path)
        end
      end

      private

      def push_details
        strong_memoize(:push_details) do
          Gitlab::Git::Push.new(project, before_sha, sha, git_ref)
        end
      end
    end
  end
end
