# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Emails
  module Notes
    def note_work_item_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)

      @work_item = @note.noteable
      @reference_prefix = @work_item.class.reference_prefix
      @target_url = work_item_url_for(@work_item, anchor: "note_#{@note.id}")
      mail_answer_note_thread(@work_item, @note, note_thread_options(reason))
    end

    def note_merge_request_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)

      @merge_request = @note.noteable
      @reference_prefix = @merge_request.class.reference_prefix
      @target_url = merge_request_url_for(@merge_request, anchor: "note_#{@note.id}")
      mail_answer_note_thread(@merge_request, @note, note_thread_options(reason))
    end

    private

    def note_thread_options(reason)
      noteable = @note.noteable
      prefix = noteable.class.reference_prefix
      {
        from: sender(@note.author_id),
        to: @recipient.notification_email_for,
        subject: subject("#{noteable.title} (#{prefix}#{noteable.iid})"),
        'X-Gisia-NotificationReason' => reason
      }
    end

    def setup_note_mail(note_id, recipient_id)
      @note = Note.find(note_id)
      @project = @note.project
      @recipient = User.find(recipient_id)
    end

    def work_item_url_for(work_item, anchor: nil)
      project = work_item.project
      return '' unless project

      ns = project.namespace.parent.full_path
      path = project.path

      if work_item.is_a?(Epic)
        namespace_project_epic_url(ns, path, work_item, anchor: anchor)
      else
        namespace_project_issue_url(ns, path, work_item, anchor: anchor)
      end
    end

    def merge_request_url_for(mr, anchor: nil)
      project = mr.target_project
      return '' unless project

      namespace_project_merge_request_url(
        project.namespace.parent.full_path,
        project.path,
        mr,
        anchor: anchor
      )
    end
  end
end
