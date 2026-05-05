# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Entry
        class JobInput < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::BaseInput

          ALLOWED_KEYS = COMMON_ALLOWED_KEYS

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS

            validate do
              next unless config.is_a?(Hash)

              errors.add(:base, 'must have a default value') if config[:default].nil?
            end
          end

          def value
            config.merge(type: config[:type] || 'string')
          end
        end
      end
    end
  end
end
