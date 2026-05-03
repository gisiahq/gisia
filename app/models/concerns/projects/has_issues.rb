# frozen_string_literal: true

module Projects
  module HasIssues
    extend ActiveSupport::Concern

    def issues_visible_to(user, ids: nil)
      base = work_items.where(type: 'Issue')
      base = base.where(id: ids) if ids.present?
      return base if user&.admin? || team.member?(user, Gitlab::Access::PLANNER)
      return base.public_only if user.nil?

      confidential_accessible = base.where(confidential: true)
        .where(
          "work_items.author_id = :uid OR work_items.id IN (SELECT work_item_id FROM work_item_assignees WHERE assignee_id = :uid)",
          uid: user.id
        )
      base.public_only.or(confidential_accessible)
    end
  end
end
