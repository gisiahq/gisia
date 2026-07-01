# frozen_string_literal: true

class IssuesFinder
  include Filterable

  private

  def base_scope
    project.issues_visible_to(current_user)
  end
end
