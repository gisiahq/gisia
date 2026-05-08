# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Key < ApplicationRecord
  belongs_to :user

  alias_attribute :fingerprint_md5, :fingerprint
  alias_attribute :name, :title

  enum :usage_type, {
    auth_and_signing: 0,
    auth: 1,
    signing: 2
  }

  before_validation :generate_fingerprint

  validates :title,
            presence: true,
            length: { maximum: 255 }

  validates :key,
            presence: true,
            ssh_key: true,
            length: { maximum: 5000 },
            format: { with: /\A(#{Gitlab::SSHPublicKey.supported_algorithms.join('|')})/ }

  validates :fingerprint_sha256,
            uniqueness: true,
            presence: { message: 'cannot be generated' }

  scope :auth, -> { where(usage_type: %i[auth auth_and_signing]) }

  def self.regular_keys
    all
  end

  def key=(value)
    write_attribute(:key, value.present? ? Gitlab::SSHPublicKey.sanitize(value) : nil)

    @public_key = nil
  end

  def regular_key?
    # Todo,
    true
  end

  def public_key
    @public_key ||= Gitlab::SSHPublicKey.new(key)
  end

  def expired?
    false
  end

  def expires_soon?
    false
  end

  private

  def generate_fingerprint
    self.fingerprint = nil
    self.fingerprint_sha256 = nil

    return unless public_key.valid?

    self.fingerprint_md5 = public_key.fingerprint unless Gitlab::FIPS.enabled?
    self.fingerprint_sha256 = public_key.fingerprint_sha256.gsub('SHA256:', '')
  end
end
