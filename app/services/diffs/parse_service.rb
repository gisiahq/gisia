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
  class ParseService
    DIFF_LINE_TYPES = {
      addition: '+',
      deletion: '-',
      context: ' ',
      no_newline: '\\'
    }.freeze

    def initialize(diff_file, expandable: false)
      @diff_file = diff_file
      @raw_diff = extract_raw_diff(diff_file)
      @expandable = expandable
    end

    def execute
      return [] unless @raw_diff.present?

      parse_diff_lines
    end

    private

    attr_reader :diff_file, :raw_diff, :expandable

    def parse_diff_lines
      lines = []
      old_line = nil
      new_line = nil

      raw_diff.lines.each do |line|
        line = line.chomp

        if hunk_header?(line)
          hunk_old, hunk_new = extract_line_numbers(line)
          lines << create_hunk_boundary_line(line, new_line || 1, hunk_new - 1, hunk_new - hunk_old)
          old_line = hunk_old
          new_line = hunk_new
          next
        end

        next if line.empty? || old_line.nil? || new_line.nil?

        diff_line = create_diff_line(line, old_line, new_line)
        lines << diff_line

        # Update line counters based on line type
        case diff_line[:type]
        when 'addition'
          new_line += 1
        when 'deletion'
          old_line += 1
        when 'context'
          old_line += 1
          new_line += 1
        end
      end

      bottom_expander = create_bottom_expander_line(old_line, new_line)
      lines << bottom_expander if bottom_expander

      lines
    end

    def hunk_header?(line)
      line.start_with?('@@')
    end

    def extract_line_numbers(hunk_line)
      # Parse "@@ -12,7 +12,6 @@" format
      match = hunk_line.match(/@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/)
      return [1, 1] unless match

      [match[1].to_i, match[2].to_i]
    end

    def create_hunk_boundary_line(line, gap_start, gap_end, offset)
      if expandable && gap_end >= gap_start
        create_expander_line(line, gap_start, gap_end, offset, false)
      else
        create_hunk_header_line(line)
      end
    end

    def create_expander_line(content, gap_start, gap_end, offset, bottom)
      {
        type: 'expander',
        content: content,
        gap_start: gap_start,
        gap_end: gap_end,
        offset: offset,
        bottom: bottom,
        old_line: nil,
        new_line: nil,
        line_code: nil,
        discussable: false,
        rich_text: content
      }
    end

    def create_bottom_expander_line(old_line, new_line)
      return unless expandable && new_line && total_new_lines
      return if total_new_lines < new_line

      offset = new_line - old_line
      size = total_new_lines - new_line + 1
      content = "@@ -#{new_line - offset},#{size} +#{new_line},#{size} @@"
      create_expander_line(content, new_line, total_new_lines, offset, true)
    end

    def total_new_lines
      return @total_new_lines if defined?(@total_new_lines)

      @total_new_lines = begin
        blob = diff_file.respond_to?(:new_blob) ? diff_file.new_blob : nil
        if blob
          blob.load_all_data!
          blob.data.lines.size
        end
      end
    end

    def create_hunk_header_line(line)
      {
        type: 'hunk_header',
        content: line,
        old_line: nil,
        new_line: nil,
        line_code: nil,
        discussable: false,
        rich_text: line
      }
    end

    def create_diff_line(line, old_line, new_line)
      first_char = line[0] || ' '
      content = line[1..-1] || ''

      type = case first_char
             when DIFF_LINE_TYPES[:addition]
               'addition'
             when DIFF_LINE_TYPES[:deletion]
               'deletion'
             when DIFF_LINE_TYPES[:context]
               'context'
             when DIFF_LINE_TYPES[:no_newline]
               'no_newline'
             else
               'context'
             end

      {
        type: type,
        content: content,
        old_line: type == 'addition' ? nil : old_line,
        new_line: type == 'deletion' ? nil : new_line,
        line_code: generate_line_code(old_line, new_line, type),
        discussable: discussable?(type),
        rich_text: syntax_highlight(content, diff_file.new_path)
      }
    end

    def generate_line_code(old_line, new_line, type)
      return nil if type == 'hunk_header'

      Gitlab::Git.diff_line_code(diff_file.file_path, new_line, old_line)
    end

    def discussable?(type)
      %w[addition deletion context].include?(type)
    end

    def syntax_highlight(content, file_path)
      # Simple HTML escaping for now - can be enhanced with proper syntax highlighting
      ERB::Util.html_escape(content)
    end

    def extract_raw_diff(diff_file)
      # Try different possible diff access patterns
      if diff_file.respond_to?(:diff) && diff_file.diff.respond_to?(:diff)
        diff_file.diff.diff
      elsif diff_file.respond_to?(:diff) && diff_file.diff.is_a?(String)
        diff_file.diff
      elsif diff_file.respond_to?(:content)
        diff_file.content
      elsif diff_file.respond_to?(:raw_diff)
        diff_file.raw_diff
      else
        Rails.logger.error "Unable to extract diff from: #{diff_file.class} - #{diff_file.methods.grep(/diff/)}"
        ""
      end
    end
  end
end