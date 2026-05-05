# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        class NoConfig
          def self.build_from(record)
            new(record)
          end

          def initialize(_record = nil); end
        end
      end
    end
  end
end
