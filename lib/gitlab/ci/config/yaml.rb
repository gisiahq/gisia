# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Yaml
        LoadError = Class.new(StandardError)

        class << self
          def load!(content, context, inputs = {}, external_context = nil)
            Loader.new(content, inputs: inputs, context: context,
              external_context: external_context).load.then do |result|
              raise result.error_class, result.error if !result.valid? && result.error_class.present?
              raise LoadError, result.error unless result.valid?

              result.content
            end
          end
        end
      end
    end
  end
end
