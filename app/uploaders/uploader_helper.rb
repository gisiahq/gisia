# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

# Extra methods for uploader
module UploaderHelper
  include Gitlab::FileMarkdownLinkBuilder

  private

  def extension_match?(extensions)
    return false unless file

    extension = file.try(:extension) || File.extname(file.path).delete('.')
    extensions.include?(extension.downcase)
  end
end
