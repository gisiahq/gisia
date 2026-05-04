# frozen_string_literal: true

module NotifyJobs
  module WorkItems
    class ReassignedWorkItemJob < ApplicationJob
      queue_as :default

      def perform(workitem_id, notification_author_id, previous_assignee_ids)
        work_item = WorkItem.find(workitem_id)
        notification_author = User.find(notification_author_id)
        previouse_assignees = User.where(id: previous_assignee_ids)

        NotificationService.new.reassigned_work_item(work_item, notification_author, previouse_assignees)
      end
    end
  end
end
