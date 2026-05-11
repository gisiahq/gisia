# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Ci
  module Inputs
    class BooleanInput < BaseInput
      extend ::Gitlab::Utils::Override

      def self.type_name
        'boolean'
      end

      override :validate_type
      def validate_type(value, default)
        return if [true, false].include?(value)

        error("#{default ? 'default' : 'provided'} value is not a boolean")
      end
    end
  end
end
