# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Diffs
  class ExpandService
    def initialize(diff_file, since:, to:, offset:)
      @diff_file = diff_file
      @since = since
      @to = to
      @offset = offset
    end

    def execute
      return [] unless diff_file.respond_to?(:new_blob_lines_between)

      diff_file.new_blob_lines_between(since, to).each_with_index.map do |content, index|
        new_line = since + index
        old_line = new_line - offset
        content = content.chomp

        {
          type: 'context',
          content: content,
          old_line: old_line,
          new_line: new_line,
          line_code: Gitlab::Git.diff_line_code(diff_file.file_path, new_line, old_line),
          discussable: true,
          rich_text: ERB::Util.html_escape(content)
        }
      end
    end

    private

    attr_reader :diff_file, :since, :to, :offset
  end
end
