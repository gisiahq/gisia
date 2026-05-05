# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Repositories
  module StreamableDiff
    extend ActiveSupport::Concern

    def diffs_for_streaming(diff_options = {})
      diffs(diff_options)
    end

    def diffs_for_streaming_by_changed_paths(diff_options = {}, &)
      offset = diff_options[:offset_index].to_i || 0
      repository.diffs_by_changed_paths(diff_refs, offset, &)
    end
  end
end
