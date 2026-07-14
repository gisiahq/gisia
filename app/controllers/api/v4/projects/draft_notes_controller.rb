# frozen_string_literal: true

module API
  module V4
    module Projects
      class DraftNotesController < ::API::V4::ProjectBaseController
        before_action :authenticate!
        before_action :find_merge_request!
        before_action :authorize_read_merge_request!
        before_action :authorize_create_note!, only: [:create, :publish, :bulk_publish]
        before_action :find_draft_note!, only: [:show, :update, :destroy, :publish]

        def index
          @draft_notes = paginate(draft_notes.order(:id))
        end

        def show; end

        def create
          @draft_note = DraftNotes::CreateService.new(@merge_request, current_user, create_attributes).execute

          if @draft_note.persisted?
            render :show, status: :created
          else
            render json: { message: @draft_note.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @draft_note.update(update_params)
            render :show
          else
            render json: { message: @draft_note.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          DraftNotes::DestroyService.new(@merge_request, current_user).execute(@draft_note)
          head :no_content
        end

        def publish
          result = DraftNotes::PublishService.new(@merge_request, current_user).execute(draft: @draft_note)

          if result[:status] == :success
            head :no_content
          else
            render json: { message: result[:message] }, status: :unprocessable_entity
          end
        end

        def bulk_publish
          result = DraftNotes::PublishService.new(@merge_request, current_user, publish_params).execute

          if result[:status] == :success
            head :no_content
          else
            render json: { message: result[:message] }, status: :unprocessable_entity
          end
        end

        private

        def find_merge_request!
          @merge_request = @project.merge_requests.find_by(iid: routing_params[:merge_request_iid])
          not_found! unless @merge_request
        end

        def authorize_read_merge_request!
          forbidden! unless can?(current_user, :read_merge_request, @merge_request)
        end

        def authorize_create_note!
          forbidden! unless can?(current_user, :create_note, @merge_request)
        end

        def draft_notes
          @draft_notes ||= @merge_request.draft_notes.authored_by(current_user)
        end

        def find_draft_note!
          @draft_note = draft_notes.find_by(id: routing_params[:id])
          not_found! unless @draft_note
        end

        def routing_params
          @routing_params ||= params.permit(:merge_request_iid, :id)
        end

        def create_attributes
          attrs = create_params.to_h.symbolize_keys
          attrs[:commit_id] = nil if attrs[:commit_id] == 'undefined'
          attrs[:discussion_id] = attrs[:discussion_id].present? ? attrs[:discussion_id].to_i : nil

          if position_params.present?
            position = build_position
            attrs[:position] = position
            attrs[:original_position] = position
          end

          attrs
        end

        def create_params
          @create_params ||= params.permit(:note, :commit_id, :discussion_id, :resolve_discussion, :internal)
        end

        def update_params
          @update_params ||= params.permit(:note)
        end

        def publish_params
          @publish_params ||= params.permit(:note)
        end

        def position_params
          @position_params ||= params.permit(position: [
            :base_sha, :start_sha, :head_sha,
            :old_path, :new_path, :old_line, :new_line, :position_type,
            { line_range: [
              { start: [:line_code, :type, :old_line, :new_line] },
              { end: [:line_code, :type, :old_line, :new_line] }
            ] }
          ])[:position]
        end

        def build_position
          Gitlab::Diff::Position.new(position_params.to_h.with_indifferent_access.slice(
            :base_sha, :start_sha, :head_sha,
            :old_path, :new_path, :old_line, :new_line,
            :position_type, :line_range
          ))
        end
      end
    end
  end
end
