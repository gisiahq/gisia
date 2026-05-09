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
  class JobDefinitionInstance < Ci::ApplicationRecord
    self.table_name = :p_ci_job_definition_instances
    self.primary_key = :job_id

    attr_accessor :partition_id

    query_constraints :job_id

    belongs_to :project

    belongs_to :job, class_name: 'Ci::Processable', inverse_of: :job_definition_instance

    belongs_to :job_definition, class_name: 'Ci::JobDefinition'

    validates :project, presence: true
    validates :job, presence: true
    validates :job_definition, presence: true

    scope :scoped_job, -> do
      where(arel_table[:job_id].eq(Ci::Processable.arel_table[:id]))
    end
  end
end

