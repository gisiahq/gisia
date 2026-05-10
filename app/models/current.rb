# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Current < ActiveSupport::CurrentAttributes
  class OrganizationNotAssignedError < RuntimeError
    def message
      'Assign an organization to Current.organization before calling it.'
    end
  end

  class OrganizationAlreadyAssignedError < RuntimeError
    def message
      'Current.organization has already been set in the current thread and should not be set again.'
    end
  end

  attribute :organization, :organization_assigned
  attribute :token_info

  def organization=(value)
    return if organization_assigned

    self.organization_assigned = true
    super(value)
  end

  private

  def organization_assigned=(value)
    organization_assigned || super(value)
  end
end
