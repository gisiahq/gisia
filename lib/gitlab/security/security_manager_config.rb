# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Security
    class SecurityManagerConfig
      def self.enabled?
        ENV.fetch('GITLAB_SECURITY_MANAGER_ROLE', 'false').downcase.in?(%w[true 1 yes on enabled])
      end
    end
  end
end
