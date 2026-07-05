# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Ci
  module Runners
    module Registrable
      extend ActiveSupport::Concern
      include Gitlab::Utils::StrongMemoize

      # Prefix assigned to runners created from the UI, instead of registered via the command line
      CREATED_RUNNER_TOKEN_PREFIX = 'glrt-'
      REGISTRATION_RUNNER_TOKEN_PREFIX = 'glrtr-'

      included do
        attr_accessor :registration_token

        strong_memoize_attr :attrs_from_token
      end

      def register!
        raise 'register failed' if !attrs_from_token || !registration_token_allowed?

        assign_attributes attrs_from_token

        Ci::BulkInsertableTags.with_bulk_insert_tags do
          Ci::Runner.transaction do
            raise ActiveRecord::Rollback unless save

            Gitlab::Ci::Tags::BulkInsert.bulk_insert_tags!([self])
          end
        end
      end

      def compute_token_expiration
        case runner_type
        when 'instance_type'
          compute_token_expiration_instance
        when 'group_type'
          compute_token_expiration_group
        when 'project_type'
          compute_token_expiration_project
        end
      end

      private

      def compute_token_expiration_instance
        return unless expiration_interval = Gitlab::CurrentSettings.runner_token_expiration_interval

        expiration_interval.seconds.from_now
      end

      def compute_token_expiration_group
        # Todo, aggregate effective_runner_token_expiration_interval across the runner's namespaces
        nil
      end

      def compute_token_expiration_project
        # Todo, aggregate effective_runner_token_expiration_interval across the runner's namespaces
        nil
      end

      def attrs_from_token
        if runner_registration_token_valid?(registration_token)
          # Create shared runner. Requires admin access
          { runner_type: :instance_type }
        elsif registration_token.present? && !Gitlab::CurrentSettings.allow_runner_registration_token
          {} # Will result in a :runner_registration_disallowed response
        end
      end

      def registration_token_allowed?
        Gitlab::CurrentSettings.allow_runner_registration_token
      end

      def runner_registration_token_valid?(registration_token)
        return false if registration_token.nil? || Gitlab::CurrentSettings.runners_registration_token.nil?

        ActiveSupport::SecurityUtils.secure_compare(registration_token,
                                                    Gitlab::CurrentSettings.runners_registration_token)
      end

      def prefix_for_new_and_legacy_runner
        return REGISTRATION_RUNNER_TOKEN_PREFIX if registration_token_registration_type?

        CREATED_RUNNER_TOKEN_PREFIX
      end
    end
  end
end
