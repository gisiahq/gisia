# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Accessible
  extend ActiveSupport::Concern

  NO_ACCESS      = 0
  MINIMAL_ACCESS = 5
  GUEST          = 10
  PLANNER        = 15
  REPORTER       = 20
  DEVELOPER      = 30
  MAINTAINER     = 40
  OWNER          = 50
  ADMIN          = 60

  included do
    validates :access_level, presence: true

    enum :access_level, {
      no_access: NO_ACCESS,
      minimal_access: MINIMAL_ACCESS,
      guest: GUEST,
      planner: PLANNER,
      reporter: REPORTER,
      developer: DEVELOPER,
      maintainer: MAINTAINER,
      owner: OWNER,
      admin: ADMIN
    }

    scope :has_access, -> { active.where('access_level > 0') }

    scope :guests, -> { where(access_level: GUEST) }
    scope :planners, -> { where(access_level: PLANNER) }
    scope :reporters, -> { where(access_level: REPORTER) }
    scope :developers, -> { where(access_level: DEVELOPER) }
    scope :maintainers, -> { where(access_level: MAINTAINER) }
    scope :non_guests, -> { where('members.access_level > ?', GUEST) }
    scope :non_minimal_access, -> { where('members.access_level > ?', MINIMAL_ACCESS) }
    scope :owners, -> { where(access_level: OWNER) }
    scope :owners_and_maintainers, -> { where(access_level: [OWNER, MAINTAINER]) }
    scope :with_user, ->(user) { where(user: user) }
    scope :by_access_level, ->(access_level) { where(access_level: access_level) }
    scope :with_at_least_access_level, ->(access_level) { where(access_level: access_level..) }
  end

  class_methods do
    def access_level_value(level)
      access_levels.fetch(level.to_s) { level.to_i }
    end
  end
end
