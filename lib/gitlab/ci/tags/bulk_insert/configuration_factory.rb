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
        class ConfigurationFactory
          def initialize(record)
            @record = record
          end

          def build
            strategy.build_from(@record)
          end

          private

          def strategy
            strategies.find(proc { NoConfig }) do |strategy|
              strategy.applies_to?(@record)
            end
          end

          def strategies
            [
              RunnerTaggingsConfiguration
            ]
          end
        end
      end
    end
  end
end
