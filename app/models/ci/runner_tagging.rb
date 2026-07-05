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
  class RunnerTagging < Ci::ApplicationRecord
    include BulkInsertSafe


    before_validation :set_runner_type, on: :create, if: -> { runner_type.nil? && runner }

    enum :runner_type, Ci::Runner.runner_types

    scope :for_runner, ->(runner_id) { where(runner_id: runner_id) }

    belongs_to :runner, class_name: 'Ci::Runner', optional: false
    belongs_to :tag, class_name: 'Ci::Tag', optional: false

    validates :runner_type, presence: true

    scope :scoped_runners, -> do
      where(arel_table[:runner_id].eq(Ci::Runner.arel_table[Ci::Runner.primary_key]))
    end

    scope :scoped_taggables, -> { scoped_runners }

    private

    def set_runner_type
      self.runner_type = runner.runner_type
    end
  end
end
