# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Ci
  module Inputs
    class ArrayInput < BaseInput
      extend ::Gitlab::Utils::Override

      def self.type_name
        'array'
      end

      override :validate_type
      def validate_type(value, default)
        return if value.is_a?(Array)

        error("#{default ? 'default' : 'provided'} value is not an array")
      end
    end
  end
end
