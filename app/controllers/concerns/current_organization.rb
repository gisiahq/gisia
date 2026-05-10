# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module CurrentOrganization
  extend ActiveSupport::Concern

  def set_current_organization
    return if ::Current.organization_assigned

    ::Current.organization = Organizations::Organization.find_by(id: Organizations::Organization::DEFAULT_ORGANIZATION_ID)
  end
end
