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
    class PipelineObjectHierarchy < ::Gitlab::ObjectHierarchy
      private

      def middle_table
        ::Ci::Sources::Pipeline.arel_table
      end

      def from_tables(cte)
        [objects_table, cte.table, middle_table]
      end

      def parent_id_column(_cte)
        middle_table[:source_pipeline_id]
      end

      def ancestor_conditions(cte)
        middle_table[:source_pipeline_id].eq(objects_table[:id])
          .and(middle_table[:pipeline_id].eq(cte.table[:id]))
          .and(project_condition)
      end

      def descendant_conditions(cte)
        middle_table[:pipeline_id].eq(objects_table[:id])
          .and(middle_table[:source_pipeline_id].eq(cte.table[:id]))
          .and(project_condition)
      end

      def project_condition
        case options[:project_condition]
        when :same then middle_table[:source_project_id].eq(middle_table[:project_id])
        when :different then middle_table[:source_project_id].not_eq(middle_table[:project_id])
        else Arel.sql('TRUE')
        end
      end

      def objects_id_columns
        objects_table[:id]
      end
    end
  end
end
