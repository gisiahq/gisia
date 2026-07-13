# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Review < ApplicationRecord
  include Participable

  belongs_to :author, class_name: 'User', foreign_key: :author_id, inverse_of: :reviews
  belongs_to :merge_request, inverse_of: :reviews
  belongs_to :project, inverse_of: :reviews

  has_many :notes, -> { order(:id) }, inverse_of: :review

  delegate :name, to: :author, prefix: true

  participant :author

  def discussion_ids
    notes.select(:discussion_id)
  end

  # Mentions are aggregated across all notes in the review so that a user
  # mentioned in any batched comment receives the (single) review email.
  def mentioned_users(current_user = nil)
    user_ids = notes.flat_map { |note| note.mentioned_users(current_user).map(&:id) }.uniq

    User.where(id: user_ids)
  end
end

Review.prepend_mod
