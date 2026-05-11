# frozen_string_literal: true

module API
  module V4
    module Projects
      class CiLintController < ::API::V4::ProjectBaseController
        before_action :authorize_read_code!, only: [:show]
        before_action :authorize_create_pipeline!, only: [:create]
        before_action :require_non_empty_repo!, only: [:show]
        before_action :find_commit!, only: [:show]

        def show
          content = @project.repository.blob_data_at(@commit.sha, @project.ci_config_path_or_default)
          dry_run_ref = params[:dry_run_ref] || @project.default_branch

          @result = Gitlab::Ci::Lint
            .new(project: @project, current_user: current_user, sha: @commit.sha)
            .legacy_validate(content, dry_run: params[:dry_run] == 'true', ref: dry_run_ref)
        end

        def create
          @result = Gitlab::Ci::Lint
            .new(project: @project, current_user: current_user)
            .legacy_validate(lint_params[:content], dry_run: lint_params[:dry_run] == 'true', ref: lint_params[:ref] || @project.default_branch)
        end

        private

        def lint_params
          @lint_params ||= params.permit(:content, :ref, :dry_run)
        end

        def require_non_empty_repo!
          not_found! if @project.empty_repo?
        end

        def find_commit!
          content_ref = params[:content_ref] || @project.repository.root_ref_sha
          @commit = @project.commit(content_ref)
          not_found! unless @commit.present?
        end

        def authorize_read_code!
          forbidden! unless can?(current_user, :read_code, @project)
        end

        def authorize_create_pipeline!
          forbidden! unless can?(current_user, :create_pipeline, @project)
        end
      end
    end
  end
end
