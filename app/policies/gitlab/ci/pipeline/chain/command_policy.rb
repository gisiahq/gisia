# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CommandPolicy < BasePolicy
          delegate(:project) { @subject.project }
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::CommandPolicy.prepend_mod

