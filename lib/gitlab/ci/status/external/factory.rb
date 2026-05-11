# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    module Status
      module External
        class Factory < Status::Factory
          def self.common_helpers
            Status::External::Common
          end
        end
      end
    end
  end
end
