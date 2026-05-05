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
        ##
        # Entry that represents a configuration of Docker services.
        #
        class Services < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Array
            validates :config, services_with_ports_alias_unique: true, if: ->(record) { record.opt(:with_image_ports) }
          end

          def value
            super.compact
          end

          def composable_class
            Entry::Service
          end
        end
      end
    end
  end
end
