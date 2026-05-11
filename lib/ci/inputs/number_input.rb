# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Ci
  module Inputs
    class NumberInput < BaseInput
      extend ::Gitlab::Utils::Override

      def self.type_name
        'number'
      end

      override :validate_type
      def validate_type(value, default)
        return if value.is_a?(Numeric)

        error("#{default ? 'default' : 'provided'} value is not a number")
      end

      override :validate_options
      def validate_options(value, all_params = {})
        allowed_options = rules ? resolved_options(all_params) : options
        return unless allowed_options && value
        return if allowed_options.include?(value)

        error("`#{value}` cannot be used because it is not in the list of the allowed options")
      end
    end
  end
end
