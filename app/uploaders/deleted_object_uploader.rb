# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

class DeletedObjectUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_location :artifacts

  def store_dir
    model.store_dir
  end
end

