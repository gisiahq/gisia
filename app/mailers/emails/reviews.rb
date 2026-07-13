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
  module Reviews
    def new_review_email(recipient_id, review_id, reason = nil)
      setup_review_email(review_id, recipient_id)

      # We must not send any internal notes to users who are not supposed to
      # be able to see them. Also, we don't want to send an empty email when
      # the review only contains internal notes.
      unless @recipient.can?(:read_internal_note, @project)
        @notes = @notes.reject(&:internal?)

        return if @notes.blank?
      end

      mail_answer_thread(@merge_request, review_thread_options(reason))
    end

    private

    def review_thread_options(reason)
      prefix = @merge_request.class.reference_prefix
      {
        from: sender(@author.id),
        to: @recipient.notification_email_for,
        subject: subject("#{@merge_request.title} (#{prefix}#{@merge_request.iid})"),
        'X-Gisia-NotificationReason' => reason
      }
    end

    def setup_review_email(review_id, recipient_id)
      @review = Review.find(review_id)
      @recipient = User.find(recipient_id)
      @author = @review.author
      @merge_request = @review.merge_request
      @project = @review.project
      @summary_note = @review.notes.detect { |note| !note.diff_note? && note.root_note? }
      @notes = @review.notes.to_a - [@summary_note].compact
      @target_url = merge_request_url_for(@merge_request)
    end
  end
end
