# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module LoopHelpers
    ##
    # This helper method repeats the same task until it's expired.
    #
    # Note: ExpiredLoopError does not happen until the given block finished.
    #       Please do not use this method for heavy or asynchronous operations.
    def loop_until(timeout: nil, limit: 1_000_000)
      raise ArgumentError unless limit

      start = Time.now

      limit.times do
        return true unless yield

        return false if timeout && (Time.now - start) > timeout
      end

      false
    end
  end
end

