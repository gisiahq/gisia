# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Pagination
    class Base
      def paginate(relation)
        raise NotImplementedError
      end

      def finalize(records)
        # Optional: Called with the actual set of records
      end
    end
  end
end
