# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authn
  module TokenField
    class PrefixHelper
      def self.prepend_instance_prefix(prefix)
        return prefix unless Feature.enabled?(:custom_prefix_for_all_token_types, :instance)
        return prefix unless instance_prefix.present?

        "#{instance_prefix}-#{prefix}"
      end

      def self.instance_prefix
        # This is an admin setting, so we should go with :instance
        # https://docs.gitlab.com/ee/development/feature_flags/#instance-actor
        return '' unless Feature.enabled?(:custom_prefix_for_all_token_types, :instance)

        Gitlab::CurrentSettings.current_application_settings.instance_token_prefix
      end
    end
  end
end
