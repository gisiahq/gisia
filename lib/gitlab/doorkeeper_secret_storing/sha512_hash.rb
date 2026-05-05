# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module DoorkeeperSecretStoring
    class Sha512Hash < ::Doorkeeper::SecretStoring::Base
      def self.transform_secret(plain_secret)
        Digest::SHA512.hexdigest plain_secret
      end

      ##
      # Determines whether this strategy supports restoring
      # secrets from the database. This allows detecting users
      # trying to use a non-restorable strategy with +reuse_access_tokens+.
      def self.allows_restoring_secrets?
        false
      end
    end
  end
end
