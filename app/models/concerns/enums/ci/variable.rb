# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Enums # rubocop: disable Gitlab/BoundedContexts -- It's within CI domain
  module Ci
    module Variable
      TYPES = {
        env_var: 1,
        file: 2
      }.freeze
    end
  end
end

