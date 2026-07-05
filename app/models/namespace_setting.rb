# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class NamespaceSetting < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_settings

  validates :default_branch_name, length: { maximum: 255 }

  NAMESPACE_SETTINGS_PARAMS = %i[
    default_branch_name
    squash_enabled
    remove_source_branch_after_merge
  ].freeze

  def self.allowed_namespace_settings_params
    NAMESPACE_SETTINGS_PARAMS
  end

  def self.shared_runners_disabled_for?(namespace_ids)
    where(namespace_id: namespace_ids, shared_runners_enabled: false).exists?
  end
end
