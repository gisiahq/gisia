# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module MergeRequestReviewerState
  extend ActiveSupport::Concern

  included do
    enum :state, {
      unreviewed: 0,
      reviewed: 1,
      requested_changes: 2,
      approved: 3,
      unapproved: 4,
      review_started: 5
    }

    validates :state,
      presence: true,
      inclusion: { in: self.states.keys }
  end
end
