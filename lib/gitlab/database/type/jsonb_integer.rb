# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Database
    module Type
      class JsonbInteger < ActiveModel::Type::Value
        def cast(value)
          Integer(value, exception: false) || value
        end
      end
    end
  end
end
