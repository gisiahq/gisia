# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

begin
  Gitlab::Workhorse.secret
rescue StandardError
  Gitlab::Workhorse.write_secret
end

# Try a second time. If it does not work this will raise.
Gitlab::Workhorse.secret
