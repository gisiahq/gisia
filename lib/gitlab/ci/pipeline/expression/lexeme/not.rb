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
          class Not < Lexeme::UnaryOperator
            PATTERN = /!/

            def self.build(_value, ahead)
              new(ahead)
            end

            def self.precedence
              1 # See: https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html
            end

            def evaluate(variables = {})
              !@operand.evaluate(variables).present?
            end
          end
        end
      end
    end
  end
end
