# frozen_string_literal: true

class Projects::CiLintController < Projects::ApplicationController
  before_action :authorize_read_code!
  before_action :find_ref!

  def show
    @branches = load_refs

    unless @project.empty_repo?
      commit = @project.commit(@ref)
      if commit
        @content = @project.repository.blob_data_at(commit.sha, @project.ci_config_path_or_default)
      end
    end

    @content ||= ''
  end

  def content
    @branches = load_refs

    unless @project.empty_repo?
      commit = @project.commit(@ref)
      @content = @project.repository.blob_data_at(commit.sha, @project.ci_config_path_or_default) if commit
    end

    @content ||= ''
  end

  def validate
    @result = Gitlab::Ci::Lint
      .new(project: @project, current_user: current_user)
      .legacy_validate(ci_lint_params[:content], dry_run: false, ref: @ref)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def ci_lint_params
    @ci_lint_params ||= params.require(:ci_lint).permit(:content, :ref)
  end

  def load_refs
    @project.repository.branch_names.sort.map { |b| { label: b, ref: b } }
  end

  def find_ref!
    return if @project.empty_repo?

    @ref = params.dig(:ci_lint, :ref).presence || @project.default_branch
    head :not_found unless @project.repository.branch_exists?(@ref)
  end

  def authorize_read_code!
    head :forbidden unless can?(current_user, :read_code, @project)
  end
end
