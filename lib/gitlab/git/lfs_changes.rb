# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Git
    class LfsChanges
      def initialize(repository, newrevs = nil)
        @repository = repository
        @newrevs = newrevs
      end

      def new_pointers(object_limit: nil, not_in: nil, dynamic_timeout: nil)
        @repository.gitaly_blob_client.get_new_lfs_pointers(@newrevs, object_limit, not_in, dynamic_timeout)
      end

      def all_pointers
        @repository.gitaly_blob_client.get_all_lfs_pointers
      end
    end
  end
end
