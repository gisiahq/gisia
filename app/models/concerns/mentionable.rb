# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

# == Mentionable concern
#
# Contains functionality related to objects that can mention Users by
# @username references in one or more text attributes.
#
module Mentionable
  extend ActiveSupport::Concern

  class_methods do
    # Indicate which attributes of the Mentionable to scan for @username mentions.
    def attr_mentionable(attr)
      mentionable_attrs << attr.to_s
    end
  end

  included do
    cattr_accessor :mentionable_attrs, instance_accessor: false do
      []
    end
  end

  def mentioned_users(_current_user = nil)
    usernames = self.class.mentionable_attrs.flat_map do |attr|
      Banzai::MentionScanner.scan(__send__(attr)).users.map(&:username) # rubocop:disable GitlabSecurity/PublicSend
    end.uniq

    return User.none if usernames.empty?

    User.by_username(usernames)
  end
end

Mentionable.prepend_mod_with('Mentionable')
