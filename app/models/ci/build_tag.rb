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
  class BuildTag < Ci::ApplicationRecord
    include BulkInsertSafe

    attr_accessor :partition_id

    self.table_name = :ci_build_tags

    belongs_to :build, class_name: 'Ci::Build', optional: false
    belongs_to :tag, class_name: 'Ci::Tag', optional: false

    validates :project_id, presence: true

    scope :scoped_builds, -> do
      where(arel_table[:build_id].eq(Ci::Build.arel_table[Ci::Build.primary_key]))
    end

    scope :scoped_taggables, -> { scoped_builds }
  end
end
