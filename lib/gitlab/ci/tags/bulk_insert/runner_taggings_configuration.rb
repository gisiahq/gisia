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
        class RunnerTaggingsConfiguration
          include ::Gitlab::Utils::StrongMemoize

          def self.applies_to?(record)
            record.is_a?(::Ci::Runner)
          end

          def self.build_from(runner)
            new(runner)
          end

          def initialize(runner)
            @runner = runner
          end

          def join_model
            ::Ci::RunnerTagging
          end

          def unique_by
            [:tag_id, :runner_id, :runner_type]
          end

          # Todo override
          def attributes_map(runner)
            {
              runner_id: runner.id,
              runner_type: runner.runner_type,
              # organization_id: runner.organization_id
            }
          end

          def uses_taggings?
            true
          end
        end
      end
    end
  end
end
