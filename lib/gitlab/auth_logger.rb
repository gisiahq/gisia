# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  class AuthLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'auth'
    end
  end
end

Gitlab::AuthLogger.prepend_mod

