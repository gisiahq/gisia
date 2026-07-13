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
  class BaseService
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize

    attr_accessor :merge_request, :current_user, :params

    def initialize(merge_request, current_user, params = {})
      @merge_request = merge_request
      @current_user = current_user
      @params = params.dup
    end

    private

    def draft_notes
      merge_request.draft_notes.order(:id).authored_by(current_user)
    end
    strong_memoize_attr :draft_notes

    def project
      merge_request.target_project
    end
  end
end
