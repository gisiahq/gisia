# frozen_string_literal: true

class Projects::StagesController < Projects::ApplicationController
  include StageIssuesFilterable

  before_action :authorize_maintainer
  before_action :set_board
  before_action :set_stage, except: [:create]

  def create
    @stage = @board.stages.build(title: stage_params[:title] || 'List')
    @stage.rank = closed_stage.rank if closed_stage

    if @stage.save
      @issues = issues_for_stage
      @can_edit_board = can_edit_board?
      @show_edit_form = true
      @closed_stage_frame_id = "stage-column-#{closed_stage.id}" if closed_stage
    else
      flash.now[:alert] = @stage.errors.full_messages.join(', ')
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def edit_stage
    @labels = @project.namespace.labels

    respond_to do |format|
      format.turbo_stream
    end
  end

  def update_stage
    @stage.update(stage_params.compact_blank)
    @issues = issues_for_stage
    @can_edit_board = can_edit_board?

    respond_to do |format|
      format.turbo_stream
    end
  end

  def update_labels
    label_ids = stage_label_params[:label_ids]&.split(',')&.reject(&:blank?) || []
    @stage.update(label_ids: label_ids)
    @issues = issues_for_stage
    @can_edit_board = can_edit_board?

    respond_to do |format|
      format.turbo_stream
    end
  end

  def search_stage_labels
    @labels = @project.namespace.labels.search_by_title(search_params[:q]).limit(10)
    @selected_ids = @stage.label_ids.map(&:to_s)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    if @stage.closed?
      flash.now[:alert] = "Cannot delete the closed stage"
    else
      @stage.destroy
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def stage_params
    @stage_params ||= params.permit(:title, :rank)
  end

  def stage_label_params
    @stage_label_params ||= params.require(:stage).permit(:label_ids)
  end

  def search_params
    @search_params ||= params.permit(:q)
  end

  def authorize_maintainer
    return redirect_to new_user_session_path unless current_user

    access_level = @project.team.max_member_access(current_user.id)
    redirect_to root_path unless access_level >= Gitlab::Access::MAINTAINER
  end

  def set_board
    @board = @project.namespace.board
  end

  def set_stage
    @stage = @board.stages.find(params[:id])
  end

  def closed_stage
    @closed_stage ||= @board.stages.find_by(kind: :closed)
  end
end
