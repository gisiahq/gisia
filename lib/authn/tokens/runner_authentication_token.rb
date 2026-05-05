# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authn
  module Tokens
    class RunnerAuthenticationToken
      def self.prefix?(plaintext)
        prefixes = [
          ::Ci::Runner.created_runner_prefix,
          ::Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX
        ]

        plaintext.start_with?(*prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        return unless self.class.prefix?(plaintext)

        @revocable = ::Ci::Runner.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Ci::Runner
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        service = ::Ci::Runners::ResetAuthenticationTokenService.new(runner: revocable, current_user: current_user)
        service.execute
      end
    end
  end
end
