# frozen_string_literal: true

module DiffsHelper
  def parse_diff_file(diff_file, expandable: false)
    Diffs::ParseService.new(diff_file, expandable: expandable).execute
  end

  def diff_expander_match_text(gap_start, gap_end, offset)
    size = gap_end - gap_start + 1
    "@@ -#{gap_start - offset},#{size} +#{gap_start},#{size} @@"
  end

  def diff_line_class(line)
    case line[:type]
    when 'addition'
      'group'
    when 'deletion'
      'group'
    when 'context'
      'group'
    when 'hunk_header'
      ''
    else
      'group'
    end
  end


  def diff_line_number(line_number)
    line_number.present? ? line_number : ''
  end

  def diff_file_id(diff_file)
    Digest::SHA1.hexdigest(diff_file.file_path)
  end

  def line_discussable?(line)
    line[:discussable] == true
  end

  def note_diff_change_position_link(note)
    return unless note.diff_note?

    merge_request = note.noteable

    if note.change_position.present? && note.change_position.diff_refs.complete?
      diff_refs = note.change_position.diff_refs
      anchor = note.change_position.line_code(merge_request.project.repository)
      version_params = merge_request.version_params_for(diff_refs)
    else
      orig_refs = note.original_position.diff_refs
      version_params = merge_request.version_params_for(orig_refs)
      return unless version_params&.key?(:start_sha)

      diff_refs = orig_refs
      anchor = note.line_code
    end

    return unless version_params

    diff = merge_request.merge_request_diffs.viewable.find_by(id: version_params[:diff_id])
    return unless diff

    version_index = merge_request.merge_request_diffs.viewable.where('id <= ?', diff.id).count
    url = diffs_namespace_project_merge_request_path(
      merge_request.project.namespace.parent.full_path,
      merge_request.project.path,
      merge_request,
      version_params.merge(anchor: anchor, diff_anchor: anchor)
    )

    { version: version_index, url: url }
  end

  def diff_comment_viewer_data(diff_file, merge_request, diff_refs)
    return {} unless merge_request

    {
      controller: "diff-comment",
      base_sha: diff_refs&.base_sha || merge_request.diff_base_sha,
      start_sha: diff_refs&.start_sha || merge_request.diff_start_sha,
      head_sha: diff_refs&.head_sha || merge_request.diff_head_sha,
      old_path: diff_file.old_path,
      new_path: diff_file.new_path,
      api_endpoint: namespace_project_merge_request_draft_notes_path(
        merge_request.target_project.namespace.parent.full_path,
        merge_request.target_project.path,
        merge_request
      )
    }
  end

  def note_original_diff_url(note)
    return unless note.diff_note?

    merge_request = note.noteable

    diffs_namespace_project_merge_request_path(
      merge_request.project.namespace.parent.full_path,
      merge_request.project.path,
      merge_request,
      { anchor: note.line_code, diff_anchor: note.line_code }
    )
  end
end

