# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module ApplicationSettingImplementation
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  FORBIDDEN_KEY_VALUE = KeyRestrictionValidator::FORBIDDEN
  VALID_RUNNER_REGISTRAR_TYPES = %w[project group].freeze
  class_methods do
    def defaults
      {
        disable_feed_token: false,
        gitlab_dedicated_instance: false,
        admin_mode: false,
        allow_runner_registration_token: true,
        valid_runner_registrars: VALID_RUNNER_REGISTRAR_TYPES,
        max_attachment_size: Settings.gitlab['max_attachment_size'],
        require_personal_access_token_expiry: true,
        default_branch_name: 'main',
        diff_max_files: Commit::DEFAULT_MAX_DIFF_FILES_SETTING,
        diff_max_lines: Commit::DEFAULT_MAX_DIFF_LINES_SETTING,
        diff_max_patch_bytes: Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES,
        custom_http_clone_url_root: nil,
        rsa_key_restriction: default_min_key_size(:rsa),
        dsa_key_restriction: default_min_key_size(:dsa),
        ecdsa_key_restriction: default_min_key_size(:ecdsa),
        ecdsa_sk_key_restriction: default_min_key_size(:ecdsa_sk),
        ed25519_key_restriction: default_min_key_size(:ed25519),
        ed25519_sk_key_restriction: default_min_key_size(:ed25519_sk),
        gitaly_timeout_default: 55,
        gitaly_timeout_fast: 10,
        gitaly_timeout_medium: 30,
        ci_max_includes: 150,
        ci_max_total_yaml_size_bytes: 314_572_800, # max_yaml_size_bytes * ci_max_includes = 2.megabyte * 150
        personal_access_token_prefix: 'gspat-',
        repository_storages_weighted: { 'default' => 100 },
        password_authentication_enabled_for_web: Settings.gitlab['signin_enabled'],
        pipeline_limit_per_user: 0,
      }
    end

    def non_production_defaults
      {}
    end

    def default_commit_email_hostname
      "users.noreply.#{Gitlab.config.gitlab.host}"
    end

    # Return the default allowed minimum key size for a type.
    # By default this is 0 (unrestricted), but in FIPS mode
    # this will return the smallest allowed key size. If no
    # size is available, this type is denied.
    #
    # @return [Integer]
    def default_min_key_size(name)
      if Gitlab::FIPS.enabled?
        Gitlab::SSHPublicKey.supported_sizes(name).select(&:positive?).min || -1
      else
        0
      end
    end

    def create_from_defaults
      build_from_defaults.tap(&:save)
    end

    def human_attribute_name(attr, _options = {})
      if attr == :default_artifacts_expire_in
        'Default artifacts expiration'
      else
        super
      end
    end
  end

  def commit_email_hostname
    super.presence || self.class.default_commit_email_hostname
  end

  def runners_registration_token
    return unless Gitlab::CurrentSettings.allow_runner_registration_token

    ensure_runners_registration_token!
  end

  def normalized_repository_storage_weights
    strong_memoize(:normalized_repository_storage_weights) do
      repository_storages_weights = repository_storages_weighted.slice(*Gitlab.config.repositories.storages.keys)
      weights_total = repository_storages_weights.values.sum

      repository_storages_weights.transform_values do |w|
        next w if weights_total == 0

        w.to_f / weights_total
      end
    end
  end

  # Choose one of the available repository storage options based on a normalized weighted probability.
  def pick_repository_storage
    normalized_repository_storage_weights.max_by { |_, weight| rand**(1.0 / weight) }.first
  end

  def allowed_key_types
    Gitlab::SSHPublicKey.supported_types.select do |type|
      key_restriction_for(type) != FORBIDDEN_KEY_VALUE
    end
  end

  def key_restriction_for(type)
    attr_name = "#{type}_key_restriction"

    has_attribute?(attr_name) ? public_send(attr_name) : FORBIDDEN_KEY_VALUE
  end

  private

  def valid_runner_registrar_combinations
    0.upto(VALID_RUNNER_REGISTRAR_TYPES.size).flat_map do |n|
      VALID_RUNNER_REGISTRAR_TYPES.permutation(n).to_a
    end
  end

  def check_valid_runner_registrars
    return if valid_runner_registrar_combinations.include?(valid_runner_registrars)

    errors.add(:valid_runner_registrars,
      format(_('%{value} is not included in the list'), value: valid_runner_registrars))
  end
end
