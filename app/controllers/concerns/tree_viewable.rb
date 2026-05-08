# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================


module TreeViewable
  extend ActiveSupport::Concern

  private

  def set_tree
    raw_logs, = tree_summary.fetch_logs

    @logs = raw_logs.index_by { |row| row['file_name'] }
    @files = tree.entries
    @current_ref = @ref

    if ref_type == ExtractsRef::RefExtractor::TAG_REF_TYPE
      @tags = repository.tag_names
    else
      @branches = repository.branch_names
    end
  end

  def tree
    repository.tree(ref, @path, recursive: false,
      skip_flat_paths: false,
      pagination_params: pagination_params,
      ref_type: ref_type || 'heads')
  end

  def tree_summary
    ::Gitlab::TreeSummary.new(
      @commit, @project, current_user,
      path: @path, offset: 0, limit: 100
    )
  end

  def ref
    params['ref'] || extract_ref_from_id || project.default_branch
  end

  private

  def extract_ref_from_id
    return if params[:id].blank?
    id = params[:id]
    repository.branch_names.find { |branch| id == branch }
  end

  def ref_extractor_params
    params.permit(:ref, :path, :ref_type).merge(id: @project.default_branch)
  end

  def pagination_params
    {
      limit: 100,
      page_token: ''
    }
  end
end

