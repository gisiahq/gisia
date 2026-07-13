# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class NotificationService
  EXCLUDED_ACTIONS = %i[async].freeze

  def self.permitted_actions
    @permitted_actions ||= (public_instance_methods(false) - EXCLUDED_ACTIONS).to_set
  end

  def async
    @async ||= Async.new(self)
  end

  def new_work_item(work_item, current_user)
    new_resource_email(work_item, current_user, :new_work_item_email)
  end

  def close_work_item(work_item, current_user)
    close_resource_email(work_item, current_user, :closed_work_item_email)
  end

  def reopen_work_item(work_item, current_user)
    reopen_resource_email(work_item, current_user, :work_item_status_changed_email, 'reopened')
  end

  def reassigned_work_item(work_item, current_user, previous_assignees = [])
    recipients = NotificationRecipients::BuildService.build_recipients(
      work_item, current_user, action: 'reassign', previous_assignees: previous_assignees
    )

    previous_assignee_ids = previous_assignees.map(&:id)

    recipients.each do |recipient|
      mailer.reassigned_work_item_email(
        recipient.user.id, work_item.id, previous_assignee_ids, current_user.id, recipient.reason
      ).deliver_later
    end
  end

  def new_merge_request(merge_request, current_user)
    new_resource_email(merge_request, current_user, :new_merge_request_email)
  end

  def close_mr(merge_request, current_user)
    close_resource_email(merge_request, current_user, :closed_merge_request_email)
  end

  def merge_mr(merge_request, current_user)
    close_resource_email(merge_request, current_user, :merged_merge_request_email)
  end

  def reopen_mr(merge_request, current_user)
    reopen_resource_email(merge_request, current_user, :reopened_merge_request_email, 'reopened')
  end

  def reassigned_merge_request(merge_request, current_user, previous_assignees = [])
    recipients = NotificationRecipients::BuildService.build_recipients(
      merge_request, current_user, action: 'reassign', previous_assignees: previous_assignees
    )

    previous_assignee_ids = previous_assignees.map(&:id)

    recipients.each do |recipient|
      mailer.reassigned_merge_request_email(
        recipient.user.id, merge_request.id, previous_assignee_ids, current_user.id, recipient.reason
      ).deliver_later
    end
  end

  def changed_reviewer_of_merge_request(merge_request, current_user, previous_reviewers = [])
    recipients = NotificationRecipients::BuildService.build_recipients(
      merge_request, current_user, action: 'change_reviewer', previous_assignees: previous_reviewers
    )

    previous_reviewer_ids = previous_reviewers.map(&:id)

    recipients.each do |recipient|
      mailer.changed_reviewer_of_merge_request_email(
        recipient.user.id, merge_request.id, previous_reviewer_ids, current_user.id, recipient.reason
      ).deliver_later
    end
  end

  def new_note(note)
    return unless note.noteable_type.present?
    return if note.system?

    recipients = NotificationRecipients::BuildService.build_new_note_recipients(note)

    email_method = case note.noteable_type
                   when 'WorkItem', 'Issue', 'Epic' then :note_work_item_email
                   when 'MergeRequest' then :note_merge_request_email
                   end

    return unless email_method

    recipients.each do |recipient|
      mailer.send(email_method, recipient.user.id, note.id, recipient.reason).deliver_later
    end
  end

  def new_review(review)
    recipients = NotificationRecipients::BuildService.build_new_review_recipients(review)

    recipients.each do |recipient|
      mailer.new_review_email(recipient.user.id, review.id, recipient.reason).deliver_later
    end
  end

  def new_member(member)
    return unless member.user

    mailer.member_access_granted_email(member.id).deliver_later
  end

  class Async
    def initialize(notification_service)
      @notification_service = notification_service
    end

    def method_missing(method, *args)
      return super unless @notification_service.respond_to?(method)

      MailScheduler::NotificationServiceJob.perform_async(method.to_s, *args)
    end

    def respond_to_missing?(method, include_private = false)
      @notification_service.respond_to?(method) || super
    end
  end

  protected

  def new_resource_email(target, current_user, method)
    return unless current_user&.can_trigger_notifications?

    recipients = NotificationRecipients::BuildService.build_recipients(
      target, target.author, action: 'new'
    )

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, recipient.reason).deliver_later
    end
  end

  def close_resource_email(target, current_user, method)
    recipients = NotificationRecipients::BuildService.build_recipients(
      target, current_user, action: 'close'
    )

    recipients.each do |recipient|
      mailer.send(
        method, recipient.user.id, target.id, current_user.id, reason: recipient.reason
      ).deliver_later
    end
  end

  def reopen_resource_email(target, current_user, method, status)
    recipients = NotificationRecipients::BuildService.build_recipients(
      target, current_user, action: 'reopen'
    )

    recipients.each do |recipient|
      mailer.send(
        method, recipient.user.id, target.id, status, current_user.id, recipient.reason
      ).deliver_later
    end
  end

  def mailer
    Notify
  end
end
