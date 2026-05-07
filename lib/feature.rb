# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Feature
  class << self
    def enabled?(*_args)
      false
    end

    def disabled?(*_args)
      true
    end

    def current_request
    end

    def logged_states
      RequestStore.fetch(:feature_flag_events) { {} }
    end

    def logged_states_for_log
      logged_states.map { |key, state| "#{key}:#{state ? 1 : 0}" }
    end
  end
end
