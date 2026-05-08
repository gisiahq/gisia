# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath

  COMMITS_DEFAULT_LIMIT = 40

  before_action :assign_ref_vars, only: :show
  before_action :set_commits, only: :show

  def show
    render action: action_name, formats: [:html]
  end

  private

  def set_commits
    options = {
      path: @path,
      limit: 40,
      offset: 0
    }

    @commits = @repository.commits(@fully_qualified_ref || @ref, **options)
  end

  def ref_extractor_params
    type = params['ref_type'] || 'heads'

    { id: params[:id], ref_type: type }
  end
end
