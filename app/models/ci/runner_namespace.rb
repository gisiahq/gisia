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
  class RunnerNamespace < Ci::ApplicationRecord
    belongs_to :runner, inverse_of: :runner_namespaces, class_name: 'Ci::Runner', optional: false

    validates :namespace_id, presence: true

    validate :only_group_or_project_runner

    private

    def only_group_or_project_runner
      return if runner&.group_type? || runner&.project_type?

      errors.add(:runner, _('is not a group or project runner'))
    end
  end
end
