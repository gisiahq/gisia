# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module DoorkeeperSecretStoring
    module Token
      class UniqueApplicationToken
        # Acronym for 'GitLab OAuth Application Secret'
        OAUTH_APPLICATION_SECRET_PREFIX_FORMAT = "gloas-%{token}"

        # Maintains compatibility with ::Doorkeeper::OAuth::Helpers::UniqueToken
        # Returns a secure random token, prefixed with a GitLab identifier.
        def self.generate(*)
          format(prefix_for_oauth_application_secret, token: SecureRandom.hex(32))
        end

        def self.prefix_for_oauth_application_secret
          ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(OAUTH_APPLICATION_SECRET_PREFIX_FORMAT)
        end
      end
    end
  end
end
