# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Ci
  class BuildSource < Ci::ApplicationRecord
    include Ci::Partitionable
    include EachBatch

    self.primary_key = :build_id

    ignore_column :pipeline_source, remove_with: '17.9', remove_after: '2025-01-15'

    enum :source, {
      scan_execution_policy: 1001,
      pipeline_execution_policy: 1002
    }.merge(::Enums::Ci::Pipeline.sources)

    belongs_to :build, class_name: 'Ci::Build', inverse_of: :build_source
    belongs_to :job, class_name: 'Ci::Processable', foreign_key: :build_id, inverse_of: :job_source

    validates :build, presence: true
  end
end
