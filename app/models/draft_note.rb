# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class DraftNote < ApplicationRecord
  include DiffPositionableNote
  include Gitlab::Utils::StrongMemoize

  PUBLISH_ATTRS = %i[noteable type note internal].freeze
  DIFF_ATTRS = %i[position original_position change_position line_code commit_id].freeze

  attr_accessor :review

  belongs_to :author, class_name: 'User'
  belongs_to :merge_request
  belongs_to :namespace

  validates :merge_request_id, presence: true
  validates :author_id, presence: true
  validates :note, presence: true
  validates :line_code, length: { maximum: 255 }, allow_nil: true

  scope :authored_by, ->(u) { where(author_id: u.id) }

  before_validation :set_namespace, prepend: true
  before_validation :set_line_code, if: :on_text?
  before_validation :set_note_type, on: :create

  def noteable
    merge_request
  end

  def noteable_id
    merge_request_id
  end

  def noteable_type
    'MergeRequest'
  end

  def project
    namespace&.project
  end

  def for_commit?
    commit_id.present?
  end

  def commit
    @commit ||= project.commit(commit_id) if commit_id.present?
  end

  def importing?
    false
  end

  def on_diff?
    position&.complete?
  end

  def type
    return note_type if note_type.present?
    return 'DiffNote' if on_diff?

    'MergeRequestNote'
  end

  def outdated?
    !!change_position&.diff_refs&.complete?
  end

  def publish_params
    attrs = PUBLISH_ATTRS.dup
    attrs.concat(DIFF_ATTRS) if on_diff?
    params = slice(*attrs).symbolize_keys
    params[:type] = type
    params[:discussion_id] = discussion_id if discussion_id.present?
    params[:review_id] = review.id if review.present?

    params
  end

  def line_code_in_diffs(diff_refs)
    return unless on_diff?

    if active?(diff_refs)
      position.line_code(repository) || line_code
    elsif diff_refs && original_position.diff_refs == diff_refs
      line_code
    elsif diff_refs && change_position.present? &&
          change_position.diff_refs == diff_refs
      change_position.line_code(repository)
    end
  end

  private

  def set_namespace
    self.namespace_id ||= merge_request&.target_project&.namespace&.id
  end

  def set_line_code
    self.line_code = line_code.presence || position.line_code(repository)
  end

  def set_note_type
    self.note_type ||= type
  end
end
