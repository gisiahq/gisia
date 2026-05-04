# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Issuable
  extend ActiveSupport::Concern
  include AfterCommitQueue

  included do
    scope :with_state, ->(*states) { where(state_id: states.flatten.map { |s|  WorkItems::HasState::STATE_ID_MAP[s] }) }

    attr_accessor :notification_author
    after_commit :notify_on_create, on: :create
    before_update :capture_previous_assignee_ids
    after_update_commit :notify_on_update
  end

  class_methods do
    def available_states
      @available_states ||= WorkItems::HasState::STATE_ID_MAP
    end
  end

  def assignee_username_list
    assignees.map(&:username).to_sentence
  end

  def assignee_or_author?(user)
    author_id == user.id || assignee?(user)
  end

  def assignee?(user)
    if assignees.loaded?
      assignees.to_a.include?(user)
    else
      assignees.exists?(user.id)
    end
  end

  def incident_type_issue?
    false
  end

  private

  def notify_on_create
    return unless notification_author

    NotificationService.new.new_work_item(self, notification_author)
  end

  def capture_previous_assignee_ids
    @previous_assignee_ids ||= WorkItemAssignee.where(work_item_id: id).pluck(:assignee_id).sort
  end

  def notify_on_update
    return unless notification_author

    if saved_change_to_state_id?
      if closed?
        NotificationService.new.close_work_item(self, notification_author)
      else
        NotificationService.new.reopen_work_item(self, notification_author)
      end
    end

    return unless @previous_assignee_ids && assignees.map(&:id).sort != @previous_assignee_ids

    NotifyJobs::WorkItems::ReassignedWorkItemJob.set(wait: 2.seconds).perform_later(self.id, notification_author.id, @previous_assignee_ids)
  end
end
