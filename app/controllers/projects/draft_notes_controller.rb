# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Projects::DraftNotesController < Projects::ApplicationController
  before_action :merge_request
  before_action :authorize_create_note!, only: %i[create publish discard]
  before_action :draft_note, only: %i[update destroy]

  def create
    @draft_note = DraftNotes::CreateService.new(merge_request, current_user, draft_note_params).execute

    return if @draft_note.persisted?

    render turbo_stream: turbo_stream.replace(
      "comment-form-#{draft_note_params[:line_code]}",
      partial: 'shared/error',
      locals: { errors: @draft_note.errors.full_messages }
    )
  end

  def update
    if @draft_note.update(update_params)
      render :update
    else
      render turbo_stream: turbo_stream.replace(
        "draft_note_#{@draft_note.id}",
        partial: 'shared/error',
        locals: { errors: @draft_note.errors.full_messages }
      )
    end
  end

  def destroy
    DraftNotes::DestroyService.new(merge_request, current_user).execute(@draft_note)

    render :destroy
  end

  def publish
    result = DraftNotes::PublishService.new(merge_request, current_user, publish_params).execute

    if result[:status] == :success
      redirect_to mr_diffs_path, notice: _('Review submitted.')
    else
      redirect_to mr_diffs_path, alert: result[:message]
    end
  end

  def discard
    DraftNotes::DestroyService.new(merge_request, current_user).execute

    redirect_to mr_diffs_path, notice: _('Pending comments discarded.')
  end

  private

  def merge_request
    @merge_request ||= project.merge_requests.find_by!(iid: routing_params[:merge_request_iid])
  end

  def draft_note
    @draft_note ||= merge_request.draft_notes.authored_by(current_user).find(routing_params[:id])
  end

  def routing_params
    @routing_params ||= params.permit(:merge_request_iid, :id)
  end

  def authorize_create_note!
    head :forbidden unless current_user&.can?(:create_note, @merge_request)
  end

  def draft_note_params
    @draft_note_params ||= params.require(:draft_note).permit(
      :note, :line_code, :position, :discussion_id, :resolve_discussion, :internal
    ).tap do |whitelisted|
      if whitelisted[:position].present?
        position = parse_position(whitelisted[:position])
        whitelisted[:position] = position
        whitelisted[:original_position] = position
      end

      whitelisted[:discussion_id] = whitelisted[:discussion_id].present? ? whitelisted[:discussion_id].to_i : nil
    end
  end

  def update_params
    @update_params ||= params.require(:draft_note).permit(:note)
  end

  def publish_params
    @publish_params ||= params.permit(:note)
  end

  def parse_position(position_json)
    return nil unless position_json.present?

    pos = Gitlab::Json.parse(position_json).with_indifferent_access
    Gitlab::Diff::Position.new(pos.slice(
      :base_sha, :start_sha, :head_sha,
      :old_path, :new_path, :old_line, :new_line,
      :position_type, :line_range
    ))
  end

  def mr_diffs_path
    diffs_namespace_project_merge_request_path(
      project.namespace.parent.full_path, project.path, merge_request
    )
  end
end
