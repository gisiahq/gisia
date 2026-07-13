# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module DraftNotes
  class DestroyService < DraftNotes::BaseService
    # If no `draft` is given it falls back to all
    # draft notes of the given merge request and user.
    def execute(draft = nil)
      drafts = draft || draft_notes

      drafts.is_a?(DraftNote) ? drafts.destroy! : drafts.delete_all
    end
  end
end
