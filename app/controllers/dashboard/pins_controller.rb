# frozen_string_literal: true

class Dashboard::PinsController < Dashboard::ApplicationController
  before_action :set_namespace
  before_action :authorize_pinnable!

  def create
    @namespace.pin_class.find_or_create_by!(user: current_user, namespace: @namespace)

    render_list
  end

  def destroy
    current_user.namespace_pins.find_by(namespace_id: @namespace.id)&.destroy

    render_list
  end

  private

  def set_namespace
    @namespace = Namespace.find(pin_params[:namespace_id] || params[:id])
  end

  def authorize_pinnable!
    head :forbidden unless pinnable_namespace_ids.include?(@namespace.id)
  end

  def pin_params
    @pin_params ||= params.permit(:namespace_id, :page)
  end

  def pinnable_namespace_ids
    @pinnable_namespace_ids ||=
      current_user.projects.pluck(:namespace_id) + current_user.authorized_groups.pluck(:namespace_id)
  end

  def render_list
    case @namespace
    when Namespaces::ProjectNamespace
      @collection = order_pinned_first(current_user.projects).page(pin_params[:page]).per(20)
      @stream_target = 'project_list'
      @stream_partial = 'dashboard/projects/project_list'
      @stream_locals = { projects: @collection, pinnable: true }
    when Namespaces::GroupNamespace
      @collection = order_pinned_first(current_user.authorized_groups).page(pin_params[:page]).per(20)
      @stream_target = 'group_list'
      @stream_partial = 'dashboard/groups/group_list'
      @stream_locals = { groups: @collection }
    end

    render 'list'
  end
end
