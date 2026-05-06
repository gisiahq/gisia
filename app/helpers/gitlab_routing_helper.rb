# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025 Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

# Shorter routing method for some project items
module GitlabRoutingHelper
  extend ActiveSupport::Concern

  include ::ProjectsHelper
  include ::ApplicationSettingsHelper
  include API::Helpers::RelatedResourcesHelpers
  include ::Routing::Projects::MembersHelper
  include ::Routing::Groups::MembersHelper
  include ::Routing::Groups::ObservabilityHelper
  include ::Routing::MembersHelper
  include ::Routing::ArtifactsHelper
  include ::Routing::PipelineSchedulesHelper
  include ::Routing::SnippetsHelper
  include ::Routing::WikiHelper
  include ::Routing::GraphqlHelper
  include ::Routing::PseudonymizationHelper
  include ::Routing::PackagesHelper
  include ::Routing::OrganizationsHelper
  included do
    Gitlab::Routing.includes_helpers(self)
  end
end

GitlabRoutingHelper.include_mod_with('GitlabRoutingHelper')
