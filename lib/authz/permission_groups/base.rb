# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Authz
  module PermissionGroups
    class Base
      include Authz::Concerns::YamlPermission
      include Gitlab::Utils::StrongMemoize

      def permissions
        @permissions ||= Array(definition[:permissions]).map(&:to_sym).uniq
      end
    end
  end
end
