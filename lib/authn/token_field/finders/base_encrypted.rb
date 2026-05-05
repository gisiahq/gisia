# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authn
  module TokenField
    module Finders
      class BaseEncrypted
        def initialize(strategy, token, unscoped)
          unless strategy.is_a?(::Authn::TokenField::Encrypted)
            raise ArgumentError,
              'Please provide an encrypted strategy.'
          end

          @strategy = strategy
          @token = token
          @unscoped = unscoped
        end

        def execute
          base_scope.find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
        end

        protected

        attr_reader :strategy, :token, :unscoped

        delegate :encrypted_field, to: :strategy

        def tokens
          @tokens ||= [
            strategy.encode(token), # encrypted_value
            Gitlab::CryptoHelper.aes256_gcm_encrypt(token) # token_encrypted_with_static_iv
          ]
        end

        def base_scope
          strategy.relation(unscoped)
        end
      end
    end
  end
end
