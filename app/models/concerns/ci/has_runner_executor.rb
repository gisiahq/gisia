# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Ci
  module HasRunnerExecutor
    extend ActiveSupport::Concern

    included do
      enum :executor_type, {
        unknown: 0,
        custom: 1,
        shell: 2,
        docker: 3,
        docker_windows: 4,
        docker_ssh: 5,
        ssh: 6,
        parallels: 7,
        virtualbox: 8,
        docker_machine: 9,
        docker_ssh_machine: 10,
        kubernetes: 11,
        docker_autoscaler: 12,
        instance: 13
      }, suffix: true
    end
  end
end
