# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Repositories
  module HasTags
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations
    end

    def create_tag(user, tag_name, target, message = nil)
      errors.clear

      errors.add(:ref, "can't be blank") and return if target.blank?
      errors.add(:tag, 'is invalid') and return unless Gitlab::GitRefValidator.validate(tag_name)

      new_tag = add_tag(user, tag_name, target, message&.strip)
      errors.add(:ref, 'is invalid') and return unless new_tag

      expire_tags_cache
      find_tag(tag_name)
    rescue Gitlab::Git::Repository::TagExistsError
      errors.add(:tag, 'already exists')
      nil
    rescue Gitlab::Git::PreReceiveError, Gitlab::Git::Repository::NoRepository => e
      errors.add(:base, e.message)
      nil
    end

    def destroy_tag(user, tag_name)
      errors.clear
      rm_tag(user, tag_name)
    rescue Gitlab::Git::PreReceiveError, Gitlab::Git::CommandError => e
      errors.add(:base, e.message)
      false
    end
  end
end
