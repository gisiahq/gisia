# frozen_string_literal: true

module API
  module V4
    module Projects
      class NotesController < ::API::V4::ProjectBaseController
        before_action :find_noteable!
        before_action :check_noteable_visibility!
        before_action :authorize_read_notes!
        before_action :find_note!, only: [:show, :update, :destroy, :resolve, :unresolve]
        before_action :authorize_create_note!, only: [:create]
        before_action :validate_create_params!, only: [:create]
        before_action :authorize_admin_note!, only: [:update, :destroy]

        def index
          order_column = index_params[:order_by] == 'updated_at' ? :updated_at : :created_at
          direction = index_params[:sort] == 'asc' ? :asc : :desc

          notes = @noteable.notes.inc_relations_for_view.order(order_column => direction, id: direction)
          notes = notes.where(system: false) if index_params[:activity_filter] == 'comments'

          @notes = paginate(notes)
        end

        def show; end

        def create
          @note = note_class.new(create_attributes)

          if @note.save
            render :show, status: :created
          else
            render json: { message: @note.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if update_params[:body].blank? && !update_params.key?(:internal)
            return render json: { message: [_("Note can't be blank")] }, status: :unprocessable_entity
          end

          @note.assign_attributes({ note: update_params[:body].presence, internal: update_params[:internal] }.compact)
          @note.updated_by = current_user
          @note.last_edited_at = Time.current

          if @note.save
            render :show
          else
            render json: { message: @note.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @note.destroy
          head :no_content
        end

        def resolve
          return not_found! unless @note.resolvable?

          @note.resolve!(current_user)
          render :show
        end

        def unresolve
          return not_found! unless @note.resolvable?

          @note.unresolve!
          render :show
        end

        private

        def find_noteable!
          @noteable = if routing_params[:merge_request_iid]
                        @project.merge_requests.find_by(iid: routing_params[:merge_request_iid])
                      elsif routing_params[:epic_iid]
                        @project.namespace.epics.find_by(iid: routing_params[:epic_iid])
                      elsif routing_params[:issue_iid]
                        @project.issues.find_by(iid: routing_params[:issue_iid])
                      end

          not_found! unless @noteable
        end

        def check_noteable_visibility!
          return unless @noteable.try(:confidential?)

          not_found! unless can?(current_user, :read_issue, @noteable)
        end

        def find_note!
          @note = @noteable.notes.find_by(id: routing_params[:id])
          not_found! unless @note
        end

        def noteable_ability_name
          return @noteable.to_ability_name if @noteable.respond_to?(:to_ability_name)

          @noteable.class.name.demodulize.underscore
        end

        def authorize_read_notes!
          forbidden! unless can?(current_user, :"read_#{noteable_ability_name}", @noteable)
        end

        def authorize_create_note!
          forbidden! unless can?(current_user, :create_note, @noteable)
        end

        def validate_create_params!
          if create_params[:body].blank?
            return render json: { message: [_("Note can't be blank")] }, status: :unprocessable_entity
          end

          if create_params.key?(:discussion_id)
            return not_found! unless discussion_parent

            if discussion_parent.system?
              return render json: { message: [_('Replies to system notes are not allowed')] },
                status: :unprocessable_entity
            end
          end

          if position_params.present? && !@noteable.is_a?(MergeRequest)
            render json: { message: [_('Position is only allowed on merge request notes')] },
              status: :unprocessable_entity
          end
        end

        def discussion_parent
          @discussion_parent ||= @noteable.notes.find_by(id: create_params[:discussion_id])
        end

        def note_class
          return DiffNote if position_params.present?

          Note.partition_model_for(@noteable.class.name)
        end

        def create_attributes
          attrs = { note: create_params[:body], internal: create_params[:internal] }.compact
          attrs[:discussion_id] = discussion_parent.id if create_params.key?(:discussion_id)

          if position_params.present?
            position = build_position
            attrs[:position] = position
            attrs[:original_position] = position
            attrs[:commit_id] = create_params[:commit_id]
          end

          attrs.merge(
            noteable: @noteable,
            noteable_type: @noteable.class.name,
            noteable_id: @noteable.id,
            namespace: @project.namespace,
            author: current_user
          )
        end

        def authorize_admin_note!
          forbidden! unless can?(current_user, :admin_note, @note)
        end

        def routing_params
          @routing_params ||= params.permit(:issue_iid, :epic_iid, :merge_request_iid, :id)
        end

        def index_params
          @index_params ||= params.permit(:order_by, :sort, :activity_filter)
        end

        def create_params
          @create_params ||= params.permit(:body, :internal, :discussion_id, :commit_id)
        end

        def update_params
          @update_params ||= params.permit(:body, :internal)
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
