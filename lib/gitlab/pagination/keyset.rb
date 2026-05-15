# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Pagination
    module Keyset
      SUPPORTED_TYPES = %w[
        Project
      ].freeze

      def self.available_for_type?(relation)
        SUPPORTED_TYPES.include?(relation.klass.to_s)
      end

      def self.available?(request_context, relation)
        order_by = request_context.page.order_by

        return false unless available_for_type?(relation)
        return false unless order_by.size == 1 && order_by[:id]

        true
      end
    end
  end
end
