# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

# The Gitlab::Middleware::Multipart middleware inserts instances of our
# own ::UploadedFile class in the Rack env of requests. These instances
# will be blocked by the 'strong parameters' feature of ActionController
# unless we somehow whitelist them. At the moment it seems the only way
# to do that is by monkey-patching.
#
module Gitlab
  module StrongParameterScalars
    def permitted_scalar?(value)
      super || value.is_a?(::UploadedFile)
    end
  end
end

module ActionController
  class Parameters
    prepend Gitlab::StrongParameterScalars
  end
end
