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
        class Inputs < ::Gitlab::Config::Entry::ComposableHash
          def compose!(deps = nil)
            super

            validate_rules! if @entries
          end

          private

          def composable_class(_name, _config)
            Header::Input
          end

          def validate_rules!
            Inputs::Validator.new(@entries).validate!
          end
        end
      end
    end
  end
end
