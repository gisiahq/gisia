# frozen_string_literal: true

class MergeRequestsFinder
  include Filterable

  def execute
    items = base_scope.ransack(ransack_params).result
    items = by_assignee(items)
    items = by_reviewer(items)
    items = by_labels(items)
    sort(items)
  end

  private

  def base_scope
    project.merge_requests
  end

  def ransack_params
    {
      status_eq: MergeRequest.statuses[params[:status].presence || 'opened'],
      author_id_eq: author_id,
      title_or_description_i_cont: params[:search]
    }.compact
  end

  def by_reviewer(items)
    return items if params[:reviewer].blank?

    user = User.find_by(username: params[:reviewer])
    return items.none unless user

    items.with_reviewer(user.id)
  end

  def default_order(items)
    status = params[:status].presence || 'opened'
    order_clause = case status
                   when 'closed' then 'merge_request_metrics.latest_closed_at DESC NULLS LAST'
                   when 'merged' then 'merge_request_metrics.merged_at DESC NULLS LAST'
                   end

    return items.order(id: :desc) unless order_clause

    MergeRequest.where(id: items.select(:id)).joins(:metrics).order(Arel.sql(order_clause))
  end
end
