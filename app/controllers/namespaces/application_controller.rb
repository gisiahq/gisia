# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Namespaces::ApplicationController < ApplicationController
  layout 'dashboard'

  skip_before_action :authenticate_user!
  before_action :namespace
  before_action :authenticate_unless_public!
  before_action :authorize_namespace_access!

  private

  def authenticate_unless_public!
    return if @namespace&.user_namespace?
    return if @namespace&.public?

    head :not_found unless current_user
  end

  def authorize_namespace_access!
    return if @namespace&.user_namespace?
    return if @namespace&.public?
    return if current_user&.admin?
    return if @namespace&.internal? && current_user
    return if current_user&.member_of_namespace_tree?(@namespace)

    render_404
  end

  def namespace
    return @namespace if @namespace
    return unless params[:namespace_id]

    full_path = params[:namespace_id]
    @namespace = Namespace.joins(:route)
                          .where(routes: { path: full_path })
                          .where(type: %w[Group User])
                          .first

    render_404 unless @namespace
  end
end
