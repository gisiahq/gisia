# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module API
  module V4
    class BaseController < ActionController::API
      rescue_from ArgumentError, with: :bad_request!

      private

      def unauthorized!
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end

      def not_found!
        render json: { error: 'Not Found' }, status: :not_found
      end

      def forbidden!(reason = nil)
        render json: { message: reason || '403 Forbidden' }, status: :forbidden
      end

      def bad_request!(error)
        render json: { message: error.message }, status: :unprocessable_entity
      end

      def can?(user, action, subject = :global)
        Ability.allowed?(user, action, subject)
      end

    end
  end
end

