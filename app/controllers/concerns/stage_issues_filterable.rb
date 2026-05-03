module StageIssuesFilterable
  extend ActiveSupport::Concern

  private

  def issues_for_stage(stage = nil)
    stage ||= @stage
    query = @project.issues_visible_to(current_user).with_label_ids(stage.label_ids).includes(:author, :labels).order(created_at: :desc)
    if stage.closed?
      query.closed
    else
      query.open
    end
  end

  def can_edit_board?
    return false unless current_user

    access_level = @project.team.max_member_access(current_user.id)
    access_level >= Gitlab::Access::MAINTAINER
  end
end

