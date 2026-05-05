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
        ##
        # This class represents the root entry of the GitLab CI configuration header.
        #
        # A header is the first document in a multi-doc YAML that contains metadata
        # and specifications about the GitLab CI configuration (the second document).
        #
        # The header is optional. A CI configuration can also be represented with a
        # YAML containing a single document.
        class Root < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[spec].freeze

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
          end

          entry :spec, Header::Spec,
            description: 'Specifications of the CI configuration.',
            inherit: false,
            default: {}

          def spec_inputs_value
            spec_entry.inputs_value
          end

          def spec_component_value
            spec_entry.component_value
          end
        end
      end
    end
  end
end
