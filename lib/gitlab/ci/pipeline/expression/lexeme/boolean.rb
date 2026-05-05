# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Boolean < Lexeme::Value
            PATTERN = /\b(?:true|false)\b/

            def self.build(string)
              new(string == 'true')
            end

            def evaluate(_variables = {})
              @value
            end

            def inspect
              @value.to_s
            end
          end
        end
      end
    end
  end
end
