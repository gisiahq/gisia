# frozen_string_literal: true

module DraftNotesHelper
  def draft_note_path(draft_note)
    merge_request = draft_note.merge_request

    namespace_project_merge_request_draft_note_path(
      merge_request.target_project.namespace.parent.full_path,
      merge_request.target_project.path,
      merge_request,
      draft_note
    )
  end

  def draft_notes_path(merge_request)
    namespace_project_merge_request_draft_notes_path(
      merge_request.target_project.namespace.parent.full_path,
      merge_request.target_project.path,
      merge_request
    )
  end

  def publish_draft_notes_path(merge_request)
    publish_namespace_project_merge_request_draft_notes_path(
      merge_request.target_project.namespace.parent.full_path,
      merge_request.target_project.path,
      merge_request
    )
  end

  def discard_draft_notes_path(merge_request)
    discard_namespace_project_merge_request_draft_notes_path(
      merge_request.target_project.namespace.parent.full_path,
      merge_request.target_project.path,
      merge_request
    )
  end
end
