# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Interpolation
        module Functions
          class PosixEscape < Base
            def self.function_expression_pattern
              /^#{name}$/
            end

            def self.name
              'posix_escape'
            end

            def execute(input_value)
              unless input_value.is_a?(String)
                error("invalid input type: #{self.class.name} can only be used with string inputs")
                return
              end

              Shellwords.shellescape(input_value)
            end
          end
        end
      end
    end
  end
end
