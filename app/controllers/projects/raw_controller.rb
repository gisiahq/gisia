# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include WorkhorseHelper

  before_action :assign_ref_vars

  def show
    @blob = @repository.blob_at(@ref, @path)

    return head :not_found unless @blob

    # Todo, lfs
    send_git_blob(@repository, @blob, inline: true)
  end

  private

  def ref_extractor_params
    { id: params[:id] }
  end
end
