# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Lfs
  class LocksFinderService < BaseService
    def execute
      success(locks: find_locks)
    rescue StandardError => ex
      error(ex.message, 500)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def find_locks
      options = params.slice(:id, :path).to_h.compact.symbolize_keys

      project.lfs_file_locks.where(options)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
