# frozen_string_literal: true

module API
  module V4
    module Projects
      class JobsController < ::API::V4::ProjectBaseController
        before_action :authorize_read_build!
        before_action :authorize_update_build!, only: [:retry]
        before_action :authorize_cancel_build!, only: [:cancel]
        before_action :job, only: [:show, :trace, :retry, :cancel]
        before_action :pipeline, only: [:pipeline_jobs]

        def index
          @jobs = @project.builds.order(id: :desc)
          @jobs = @jobs.with_status(params[:scope]) if params[:scope].present?
          @jobs = paginate(@jobs)
        end

        def pipeline_jobs
          @jobs = @pipeline.builds.order(id: :desc)
          @jobs = @jobs.with_status(params[:scope]) if params[:scope].present?
          @jobs = paginate(@jobs)
          render 'api/v4/projects/jobs/index'
        end

        def show; end

        def trace
          @job.trace.read do |stream|
            content = stream.raw
            render plain: content, content_type: 'text/plain'
          end
        rescue StandardError
          render plain: '', content_type: 'text/plain'
        end

        def retry
          return render json: { message: 'Job is not retryable' }, status: :bad_request unless @job.retryable?

          new_job = @job.retry!(current_user)
          @job = new_job
          render :show
        end

        def cancel
          return render json: { message: 'Job is not cancelable' }, status: :bad_request unless @job.cancelable?

          @job.cancel
          render :show
        end

        private

        def job
          @job ||= @project.builds.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          not_found!
        end

        def pipeline
          @pipeline ||= @project.all_pipelines.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          not_found!
        end

        def authorize_read_build!
          forbidden! unless can?(current_user, :read_build, @project)
        end

        def authorize_update_build!
          forbidden! unless can?(current_user, :update_build, @project)
        end

        def authorize_cancel_build!
          forbidden! unless can?(current_user, :cancel_build, @project)
        end
      end
    end
  end
end
