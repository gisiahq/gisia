# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class ProjectPipelineSetting < ApplicationRecord
  belongs_to :project

  validates :build_timeout, presence: true, numericality: { greater_than: 0 }
  validates :project_id, presence: true, uniqueness: true

  def auto_cancel_pending_pipelines?
    auto_cancel_pending_pipelines
  end
end