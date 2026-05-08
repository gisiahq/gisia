# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Loggable
    ANONYMOUS = '<Anonymous>'

    def build_structured_payload(**params)
      { class: self.class.name || ANONYMOUS }.merge(params).stringify_keys
    end
  end
end

