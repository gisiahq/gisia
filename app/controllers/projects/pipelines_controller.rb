# frozen_string_literal: true

class Projects::PipelinesController < Projects::ApplicationController
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :validate_ref_prefix!, only: [:create]
  before_action :pipeline, only: [:show, :jobs]

  def index
    @pipelines = project.all_pipelines
    @pipelines = @pipelines.where(status: pipeline_params[:status]) if pipeline_params[:status].present?
    @pipelines = @pipelines.where(ref: pipeline_params[:ref]) if pipeline_params[:ref].present?
    @pipelines = @pipelines.ransack(sha_i_cont: pipeline_params[:search]).result(distinct: true) if pipeline_params[:search].present?
    @pipelines = @pipelines.order(id: :desc).page(params[:page]).per(20)

    @refs = project.ci_refs.pluck(:ref_path).map { |ref_path| ref_path.sub(/\Arefs\/(heads|tags)\//, '') }.compact.sort
    @statuses = Ci::HasStatus::AVAILABLE_STATUSES
  end

  def new
    @ref = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{project.default_branch}"
    @branches, @tags = load_refs
  end

  def create
    new_pipeline = Ci::Pipeline.build_from(
      project, current_user,
      { ref: pipeline_create_params[:ref] },
      :web, { save_on_errors: false }
    )

    if new_pipeline.persisted?
      redirect_to helpers.pipelines_path(project), notice: _('Pipeline created successfully.')
    else
      @ref = pipeline_create_params[:ref]
      @branches, @tags = load_refs
      flash.now[:alert] = new_pipeline.errors.full_messages.join(', ')
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def jobs
    @jobs = pipeline.builds
  end

  private

  def pipeline
    @pipeline = project.all_pipelines.find(params[:id])
  end

  def pipeline_params
    @pipeline_params ||= params.permit(:status, :ref, :search)
  end

  def pipeline_create_params
    @pipeline_create_params ||= params.permit(:ref)
  end

  def validate_ref_prefix!
    ref = pipeline_create_params[:ref]
    return if Gitlab::Git.branch_ref?(ref) || Gitlab::Git.tag_ref?(ref)

    flash[:alert] = _('ref must include a valid prefix')
    redirect_to new_project_pipeline_path(@project)
  end

  def load_refs
    branches = project.repository.branch_names.sort.map { |b| { label: b, ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}#{b}" } }
    tags = project.repository.tag_names.sort.map { |t| { label: t, ref: "#{Gitlab::Git::TAG_REF_PREFIX}#{t}" } }
    [branches, tags]
  end

  def authorize_read_pipeline!
    forbidden! unless can?(current_user, :read_pipeline, @project)
  end

  def authorize_create_pipeline!
    forbidden! unless can?(current_user, :create_pipeline, @project)
  end
end
