# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class ProjectsController < Projects::ApplicationController
  include VerifiesParentNamespace
  include ExtractsPath
  include TreeViewable
  include Projects::Parameterizable

  before_action :check_empty_repository, only: [:show]
  before_action :assign_ref_vars, only: [:show]
  before_action :set_tree, only: [:show]
  before_action :authorize_edit_project!, only: %i[edit update]
  before_action :set_available_namespaces, only: %i[edit update]
  before_action :verify_namespace_ownership, only: %i[update]

  def index; end

  def new; end

  def edit
    @project.build_namespace unless @project.namespace
    @project.namespace_parent_id = @project.namespace&.parent_id
  end

  def create; end

  def update
    if @project.update(project_params)
      redirect_to edit_namespace_project_path(@project.namespace.parent.full_path, @project.path), notice: 'Project was successfully updated.'
    else
      flash[:errors] = @project.errors.full_messages
      redirect_to edit_namespace_project_path(@project.namespace.parent.full_path, @project.path), alert: 'Please correct the errors below.'
    end
  end

  def destroy; end

  def show;end

  private

  def check_empty_repository
    return unless @project.repository_exists? && @project.empty_repo?

    render 'empty'
  end

  def project_params
    @project_params ||= params.require(:project).permit(
      :name,
      :path,
      :description,
      :workflows,
      :namespace_parent_id,
      namespace_attributes: %i[id parent_id visibility_level]
    )
  end

  def authorize_edit_project!
    return if current_user&.admin?
    return if @project.team.member?(current_user, Accessible::MAINTAINER)

    head :forbidden
  end

  def set_available_namespaces
    @available_namespaces = current_user.namespaces_for_project_creation
  end

  def verify_namespace_ownership
    parent_id = requested_parent_namespace_id&.to_i
    return unless parent_id
    return if parent_id == @project.namespace.parent_id

    verify_parent_namespace!
    return if performed?
    return if current_user.admin? || @project.team.member?(current_user, Accessible::OWNER)

    redirect_to namespace_project_path(@project.namespace.parent.full_path, @project.path),
      alert: _('Only an owner of the project can move it to another namespace.')
  end

  def requested_parent_namespace_id
    project_params[:namespace_parent_id].presence
  end

  def reject_parent_namespace!
    redirect_to namespace_project_path(@project.namespace.parent.full_path, @project.path),
      alert: _('You are not authorized to use this namespace.')
  end
end
