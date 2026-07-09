# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class ProcessableObjectHierarchy < ::Gitlab::ObjectHierarchy
      private

      def middle_table
        ::Ci::BuildNeed.arel_table
      end

      def from_tables(cte)
        [objects_table, cte.table, middle_table]
      end

      def parent_id_column(_cte)
        middle_table[:name]
      end

      def ancestor_conditions(cte)
        middle_table[:name].eq(objects_table[:name]).and(
          middle_table[:build_id].eq(cte.table[:id])
        ).and(
          objects_table[:commit_id].eq(cte.table[:commit_id])
        )
      end

      def descendant_conditions(cte)
        middle_table[:build_id].eq(objects_table[:id]).and(
          middle_table[:name].eq(cte.table[:name])
        ).and(
          objects_table[:commit_id].eq(cte.table[:commit_id])
        )
      end
    end
  end
end
