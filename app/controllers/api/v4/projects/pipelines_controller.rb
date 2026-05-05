# frozen_string_literal: true

module API
  module V4
    module Projects
      class PipelinesController < ::API::V4::ProjectBaseController
        before_action :authorize_read_pipeline!
        before_action :authorize_create_pipeline!, only: [:create]
        before_action :authorize_update_pipeline!, only: [:retry, :cancel]
        before_action :authorize_destroy_pipeline!, only: [:destroy]
        before_action :pipeline, only: [:show, :retry, :cancel, :destroy]
        before_action :require_ref!, only: [:create]
        before_action :resolve_and_authorize_ref!, only: [:create]
        before_action :require_cancelable!, only: [:cancel]

        def index
          @pipelines = @project.all_pipelines
          @pipelines = @pipelines.for_status(params[:status]) if params[:status].present?
          @pipelines = @pipelines.for_ref(params[:ref]) if params[:ref].present?
          @pipelines = @pipelines.for_sha(params[:sha]) if params[:sha].present?
          @pipelines = paginate(@pipelines.order_id_desc)
        end

        def show; end

        def create
          new_pipeline = Ci::Pipeline.build_from(
            @project, current_user,
            { ref: pipeline_params[:ref], variables_attributes: pipeline_params[:variables] || [] },
            :api, {}
          )

          if new_pipeline.persisted?
            @pipeline = new_pipeline
            render :show, status: :created
          else
            render json: { message: new_pipeline.errors.full_messages }, status: :bad_request
          end
        end

        def retry
          failed = @pipeline.builds.latest.failed_or_canceled
          return render json: { message: 'Nothing to retry' }, status: :bad_request if failed.none?

          failed.each { |build| build.retry!(current_user) }
          render :show
        end

        def cancel
          result = Ci::CancelPipelineService.new(pipeline: @pipeline, current_user: current_user).force_execute

          if result.success?
            render :show
          else
            render json: { message: result.message }, status: :bad_request
          end
        end

        def destroy
          @pipeline.destroy
          head :no_content
        end

        private

        def pipeline
          @pipeline ||= @project.all_pipelines.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          not_found!
        end

        def pipeline_params
          @pipeline_params ||= params.permit(:ref, variables: [:key, :value, :variable_type])
        end

        def require_ref!
          render json: { message: 'ref is missing' }, status: :bad_request if pipeline_params[:ref].blank?
        end

        def resolve_and_authorize_ref!
          ref = pipeline_params[:ref]
          if @project.repository.ambiguous_ref?(ref)
            return render json: { message: 'Ref is ambiguous' }, status: :unprocessable_entity
          elsif @project.repository.branch_exists?(ref)
            pipeline_params[:ref] = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{ref}"
          elsif @project.repository.tag_exists?(ref)
            pipeline_params[:ref] = "#{Gitlab::Git::TAG_REF_PREFIX}#{ref}"
          end

          access = Gitlab::UserAccess.new(current_user, container: @project)

          if Gitlab::Git.tag_ref?(pipeline_params[:ref])
            forbidden! unless access.can_create_tag?(Gitlab::Git.ref_name(pipeline_params[:ref]))
          elsif Gitlab::Git.branch_ref?(pipeline_params[:ref])
            forbidden! unless access.can_update_branch?(Gitlab::Git.ref_name(pipeline_params[:ref]))
          end
        end

        def require_cancelable!
          render json: { message: 'Pipeline is not cancelable' }, status: :bad_request unless @pipeline.cancelable?
        end

        def authorize_read_pipeline!
          forbidden! unless current_user.can?(:read_pipeline, @project)
        end

        def authorize_create_pipeline!
          forbidden! unless current_user.can?(:create_pipeline, @project)
        end

        def authorize_update_pipeline!
          forbidden! unless current_user.can?(:update_pipeline, @project)
        end

        def authorize_destroy_pipeline!
          forbidden! unless current_user.can?(:destroy_pipeline, @project)
        end
      end
    end
  end
end
