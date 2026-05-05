# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        class BuildsTagsConfiguration
          def self.applies_to?(record)
            record.is_a?(::Ci::Build)
          end

          def self.build_from(job)
            new(job.project)
          end

          def initialize(project)
            @project = project
          end

          def join_model
            ::Ci::BuildTag
          end

          def unique_by
            [:tag_id, :build_id]
          end

          def attributes_map(job)
            {
              build_id: job.id,
              project_id: job.project_id
            }
          end

          def polymorphic_taggings?
            true
          end

          def monomorphic_taggings?(_taggable)
            true
          end
        end
      end
    end
  end
end
