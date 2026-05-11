# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    module Status
      module External
        module Common
          def label
            subject.description.presence || super
          end

          def has_details?
            subject.target_url.present? &&
              can?(user, :read_commit_status, subject)
          end

          def details_path
            subject.target_url
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
