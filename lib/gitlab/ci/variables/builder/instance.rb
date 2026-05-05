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
        class Instance
          include Gitlab::Utils::StrongMemoize

          def secret_variables(protected_ref: false, only: nil)
            variables = if protected_ref
                          ::Ci::InstanceVariable.all_cached
                        else
                          ::Ci::InstanceVariable.unprotected_cached
                        end

            # Due to caching logic these variables are an array so we can't use ActiveRecord.where
            variables = variables.filter { |v| only.nil? || v.key.in?(only) }

            Gitlab::Ci::Variables::Collection.new(variables)
          end
        end
      end
    end
  end
end
