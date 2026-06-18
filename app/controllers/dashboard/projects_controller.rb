# frozen_string_literal: true

class Dashboard::ProjectsController < Dashboard::ApplicationController
  include Projects::Parameterizable
  before_action :set_project, only: %i[destroy]
  before_action :set_available_namespaces, only: %i[new create]
  before_action :verify_namespace_ownership, only: %i[create]
  before_action :authorize_destroy_project!, only: %i[destroy]

  def index
    @projects = order_pinned_first(current_user.projects).page(params[:page]).per(20)
  end

  def new
    @project = Project.new
    @project.build_namespace
    @selected_namespace_id = params[:namespace_id]&.to_i || @available_namespaces.first&.id
  end

  def create
    @project = Project.new(create_params)

    if @project.save
      redirect_to "/#{@project.full_path}", notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  def destroy
    @project.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_projects_path }
    end
  end

  private

  def set_project
    @project = Project.includes(:namespace).find(params[:id])
  end

  def create_params
    params.require(:project).permit(
      :name,
      :path,
      :description,
      :namespace_parent_id,
      namespace_attributes: %i[id parent_id visibility_level]
    ).tap { |p| p[:namespace_attributes]&.merge!(creator_id: current_user.id) }
  end

  def set_available_namespaces
    @available_namespaces = available_namespaces_for_user
  end

  def verify_namespace_ownership
    return unless params[:project]&.dig(:namespace_parent_id).present?

    namespace_parent_id = params[:project][:namespace_parent_id].to_i
    unless available_namespaces_for_user.exists?(id: namespace_parent_id)
      redirect_to dashboard_projects_path, alert: 'You are not authorized to use this namespace.'
    end
  end

  def authorize_destroy_project!
    return if current_user.admin?
    return if @project.team.member?(current_user, Accessible::OWNER)

    redirect_to dashboard_projects_path, alert: 'You are not authorized to perform this action.'
  end
end
