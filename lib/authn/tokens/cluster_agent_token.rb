# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authn
  module Tokens
    class ClusterAgentToken
      def self.prefix?(plaintext)
        prefixes = [::Clusters::AgentToken.glagent_prefix,
          ::Clusters::AgentToken::TOKEN_PREFIX].uniq

        plaintext.start_with?(*prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        return unless self.class.prefix?(plaintext)

        @revocable = ::Clusters::AgentToken.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Clusters::AgentToken
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        service = ::Clusters::AgentTokens::RevokeService.new(token: revocable, current_user: current_user)
        service.execute
      end
    end
  end
end
