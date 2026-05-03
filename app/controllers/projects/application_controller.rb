# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Projects::ApplicationController < ApplicationController
  include RoutableActions

  layout 'project'

  skip_before_action :authenticate_user!
  before_action :project
  before_action :authenticate_unless_public!
  before_action :repository
  before_action :authorize_project_access!

  private

  def require_project_member!
    forbidden! unless @project&.team&.member?(current_user)
  end

  def authenticate_unless_public!
    return if @project&.public?

    head :not_found unless current_user
  end

  def authorize_project_access!
    return if @project&.public?
    return if current_user&.admin?
    return if @project&.internal? && current_user
    return if @project && @project.team.member?(current_user)

    head :not_found
  end

  def project
    return @project if @project
    return unless params[:project_id] || params[:id]

    path = File.join(params[:namespace_id], params[:project_id] || params[:id])

    @project = find_routable!(Project, path, request.fullpath, extra_authorization_proc: auth_proc)
  end

  def auth_proc
    ->(project) { !project.pending_delete? }
  end

  def repository
    @repository ||= @project.repository
  end
end
