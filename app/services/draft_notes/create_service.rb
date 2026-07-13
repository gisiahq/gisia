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
  class CreateService < DraftNotes::BaseService
    def execute
      if params[:discussion_id].present?
        return base_error(_('Thread to reply to cannot be found')) unless discussion
        return base_error(_('Replies to system notes are not allowed')) if discussion.system?
      end

      draft_note = DraftNote.new(params)
      draft_note.merge_request = merge_request
      draft_note.author = current_user
      draft_note.save

      draft_note
    end

    private

    def base_error(text)
      DraftNote.new.tap do |draft|
        draft.errors.add(:base, text)
      end
    end

    def discussion
      @discussion ||= merge_request.notes.find_by(id: params[:discussion_id])
    end
  end
end
