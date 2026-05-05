# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Yaml
        class Context
          attr_reader :variables, :component

          def initialize(variables: [], component: {})
            @variables = variables
            @component = component
          end
        end
      end
    end
  end
end
