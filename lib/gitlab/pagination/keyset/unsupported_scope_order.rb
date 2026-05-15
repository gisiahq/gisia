# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Pagination
    module Keyset
      class UnsupportedScopeOrder < StandardError
        DEFAULT_ERROR_MESSAGE = <<~MSG
        The order on the scope does not support keyset pagination. You might need to define a custom Order object.\n
        See https://docs.gitlab.com/ee/development/database/keyset_pagination.html#complex-order-configuration\n
        Or the Gitlab::Pagination::Keyset::Order class for examples
        MSG

        def message
          DEFAULT_ERROR_MESSAGE
        end
      end
    end
  end
end
