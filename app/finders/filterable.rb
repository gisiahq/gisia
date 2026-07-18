# frozen_string_literal: true

module Filterable
  attr_reader :project, :current_user, :params

  def initialize(project, current_user, params = {})
    @project = project
    @current_user = current_user
    @params = params
  end

  def execute
    items = base_scope.ransack(ransack_params).result
    items = by_assignee(items)
    items = by_labels(items)
    sort(items)
  end

  private

  def base_scope
    raise NotImplementedError
  end

  def ransack_params
    {
      state_id_eq: WorkItems::HasState::STATE_ID_MAP[params[:status].presence || 'opened'],
      author_id_eq: author_id,
      title_or_description_i_cont: params[:search]
    }.compact
  end

  def author_id
    return if params[:author].blank?

    User.find_by(username: params[:author])&.id || 0
  end

  def by_assignee(items)
    return items if params[:assignee].blank?

    user = User.find_by(username: params[:assignee])
    return items.none unless user

    items.with_assignee(user.id)
  end

  def by_labels(items)
    label_titles = Array(params[:label]).reject(&:blank?)
    return items if label_titles.empty?

    label_ids = project.available_labels.where(title: label_titles).pluck(:id)
    items.with_label_ids(label_ids)
  end

  def sort(items)
    case params[:sort]
    when 'created_at_asc' then return items.order(created_at: :asc)
    when 'created_at_desc' then return items.order(created_at: :desc)
    when 'updated_at_asc' then return items.order(updated_at: :asc)
    when 'updated_at_desc' then return items.order(updated_at: :desc)
    end

    match = params[:sort].to_s.match(/\A(.+)_(asc|desc)\z/)
    return default_order(items) unless match

    items.order_by_label_rank(match[1], match[2].to_sym)
  end

  def default_order(items)
    params[:status] == 'closed' ? items.order(closed_at: :desc) : items.order(created_at: :desc)
  end
end
