# frozen_string_literal: true

class IssuesFinder < WorkItemsFinder
  private

  def base_scope
    project.issues_visible_to(current_user)
  end
end
