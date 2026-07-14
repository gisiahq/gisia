# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module DraftNotes
  class PublishService < DraftNotes::BaseService
    def execute(draft: nil)
      return publish_draft_note(draft) if draft

      return error(_('There are no pending comments to publish')) if draft_notes.blank?

      review = nil
      created_notes = nil

      ApplicationRecord.transaction do
        review = Review.create!(
          author: current_user,
          merge_request: merge_request,
          project: project,
          commit_id: merge_request.diff_head_sha
        )

        created_notes = draft_notes.map do |draft|
          draft.review = review
          create_note_from_draft(draft)
        end

        summary_note = create_summary_note(review)
        draft_notes.delete_all

        create_review_activity(review, summary_note)
      end

      keep_around_commits(created_notes)

      NotificationService.new.new_review(review)

      success(review: review)
    rescue ActiveRecord::RecordInvalid => e
      error("Unable to save #{e.record.class.name}: #{e.record.errors.full_messages.join(', ')}")
    end

    private

    def publish_draft_note(draft)
      note = nil

      ApplicationRecord.transaction do
        note = create_note_from_draft(draft)
        draft.delete
      end

      keep_around_commits([note])

      success(note: note)
    rescue ActiveRecord::RecordInvalid => e
      error("Unable to save #{e.record.class.name}: #{e.record.errors.full_messages.join(', ')}")
    end

    def create_note_from_draft(draft)
      note_params = draft.publish_params
      klass = note_params.delete(:type) == 'DiffNote' ? DiffNote : MergeRequestNote

      note = klass.new(note_params.merge(
        noteable: merge_request,
        namespace_id: draft.namespace_id,
        author: draft.author
      ))
      note.skip_keep_around_commits = true
      note.save!

      resolve_discussion(draft)

      note
    end

    def resolve_discussion(draft)
      return unless draft.discussion_id.present? && draft.resolve_discussion?

      parent = merge_request.notes.find_by(id: draft.discussion_id)
      parent&.resolve!(current_user)
    end

    def create_summary_note(review)
      return if params[:note].blank?

      MergeRequestNote.create!(
        noteable: merge_request,
        namespace: project.namespace,
        author: current_user,
        note: params[:note],
        review_id: review.id
      )
    end

    def create_review_activity(review, summary_note)
      MergeRequestActivity.create!(
        trackable_type: 'MergeRequest',
        trackable_id: merge_request.id,
        author_id: current_user.id,
        action_type: :review_added,
        note_id: summary_note&.id,
        details: { review_id: review.id }
      )
    end

    def keep_around_commits(notes)
      shas = notes.select(&:diff_note?).flat_map(&:shas).uniq
      return if shas.empty?

      Gitlab::GitalyClient.allow_n_plus_1_calls do
        project.repository.keep_around(*shas, source: self.class.name)
      end
    end
  end
end
