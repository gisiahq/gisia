# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath
  include TreeViewable

  rescue_from ExtractsRef::RefExtractor::InvalidPathError do
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  before_action :assign_ref_vars, only: [:show]
  before_action :set_tree, only: [:show]

  def show; end

  private

  def ref_extractor_params
    params.permit(:id, :ref, :path, :ref_type)
  end
end
