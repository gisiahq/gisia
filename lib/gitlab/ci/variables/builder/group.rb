# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    module Variables
      class Builder
        class Group
          include Gitlab::Utils::StrongMemoize

          def initialize(group)
            @group = group
          end

          def secret_variables(environment:, protected_ref: false, only: nil)
            return [] unless group

            variables = base_scope
            variables = variables.unprotected unless protected_ref
            variables = variables.for_environment(environment)
            variables = variables.by_key(only) if only
            variables = variables.group_by(&:group_id)
            variables = list_of_ids.reverse.flat_map { |group| variables[group.id] }.compact
            Gitlab::Ci::Variables::Collection.new(variables)
          end

          private

          attr_reader :group

          def base_scope
            strong_memoize(:base_scope) do
              ::Ci::GroupVariable.for_groups(list_of_ids)
            end
          end

          def list_of_ids
            strong_memoize(:list_of_ids) do
              if group.root_ancestor.use_traversal_ids?
                [group] + group.ancestors(hierarchy_order: :asc)
              else
                [group] + group.ancestors
              end
            end
          end
        end
      end
    end
  end
end
