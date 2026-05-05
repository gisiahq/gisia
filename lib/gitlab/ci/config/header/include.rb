# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Header
        class Include < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseInclude

          # Header includes only use the common allowed keys (no additional keys)
          ALLOWED_KEYS = [] + COMMON_ALLOWED_KEYS

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end
        end
      end
    end
  end
end
