# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Header
        class Input
          ##
          # Input rules define conditional options and defaults based on expressions.
          #
          class Rules < ::Gitlab::Config::Entry::ComposableArray
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, type: Array
            end

            def composable_class
              Gitlab::Ci::Config::Header::Input::Rules::Rule
            end

            def errors
              super.map do |error|
                error.gsub(/(?:header:spec:inputs:)?(\w+):rules:rule (?:base |config )?(.+)/) do
                  "`#{::Regexp.last_match(1)}` input: #{::Regexp.last_match(2)}"
                end
              end
            end
          end
        end
      end
    end
  end
end
