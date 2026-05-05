# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a list of include.
        #
        class Includes < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseIncludes

          def composable_class
            Entry::Include
          end
        end
      end
    end
  end
end
