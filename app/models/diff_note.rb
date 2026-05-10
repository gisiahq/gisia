# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class DiffNote < Note
  include NoteOnDiff
  include DiffPositionableNote
  include Gitlab::Utils::StrongMemoize
  include Notes::HasMergeRequest
  include Notes::HasNoteDiffFile

  validates :original_position, presence: true
  validates :position, presence: true
  validates :line_code, presence: true

  validates :noteable_type, inclusion: { in: ->(_note) { noteable_types } }
  validate :positions_complete
  validate :verify_supported, unless: :importing?

  before_validation :set_line_code, if: :on_text?, unless: :importing?
  after_save :keep_around_commits, unless: -> { importing? || skip_keep_around_commits }

  def self.noteable_types
    %w[MergeRequest]
  end

  def created_at_diff?(diff_refs)
    return false unless supported?

    original_position.diff_refs == diff_refs
  end

  def line_code_in_diffs(diff_refs)
    if active?(diff_refs)
      position.line_code(repository) || line_code
    elsif diff_refs && created_at_diff?(diff_refs)
      line_code
    elsif diff_refs && change_position.present? &&
          change_position.diff_refs == diff_refs
      change_position.line_code(noteable.project.repository)
    end
  end

  private

  def set_line_code
    self.line_code = self.line_code.presence || self.position.line_code(repository)
  end

  def importing?
    false
  end

  def verify_supported
    return if supported?

    errors.add(:noteable, "doesn't support new-style diff notes")
  end

  def positions_complete
    return if self.original_position.complete? && self.position.complete?

    errors.add(:position, 'is incomplete')
  end
end
