# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Lfs # rubocop:disable Gitlab/BoundedContexts -- These classes already exist so need some work before possible to move
  class BaseFileLockService < BaseService
  end
end

Lfs::BaseFileLockService.prepend_mod
