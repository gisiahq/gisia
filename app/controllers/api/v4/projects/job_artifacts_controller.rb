# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module API
  module V4
    module Projects
      class JobArtifactsController < ::API::V4::ProjectBaseController
        include SendFileUpload
        include WorkhorseHelper
        include API::V4::Paginatable

        before_action :authorize_read_artifacts!
        before_action :authorize_destroy_artifacts!, only: %i[destroy expire_all]
        before_action :authorize_update_artifacts!, only: [:keep]
        before_action :job, only: %i[download browse raw keep destroy]
        before_action :require_artifacts!, only: %i[download raw keep]
        before_action :require_available_artifacts!, only: %i[browse raw]
        before_action :require_artifacts_metadata!, only: [:browse]
        before_action :require_artifacts_for_keep!, only: [:keep]
        before_action :find_build_by_ref!, only: %i[download_by_ref raw_by_ref]
        before_action :require_build_artifacts!, only: %i[download_by_ref raw_by_ref]

        def download
          send_upload(job.artifacts_file, attachment: job.artifacts_file.filename)
        end

        def browse
          directory = params[:path].present? ? "#{params[:path].delete_suffix('/')}/" : ''
          recursive = ActiveModel::Type::Boolean.new.cast(params[:recursive])

          entry = job.artifacts_metadata_entry(directory, recursive: recursive)
          not_found! unless entry.exists?

          entries = recursive ? entry.children : entry.directories(parent: false) + entry.files
          page = paginate(::Kaminari.paginate_array(entries))

          render json: page.map { |e| { name: e.name, type: e.type, path: e.path } }
        end

        def raw
          path = Gitlab::Ci::Build::Artifacts::Path.new(params[:artifact_path])
          return render json: { message: 'invalid path' }, status: :bad_request unless path.valid?

          send_artifacts_entry(job.artifacts_file, path)
        end

        def download_by_ref
          send_upload(@build.artifacts_file, attachment: @build.artifacts_file.filename)
        end

        def raw_by_ref
          path = Gitlab::Ci::Build::Artifacts::Path.new(params[:artifact_path])
          return render json: { message: 'invalid path' }, status: :bad_request unless path.valid?

          send_artifacts_entry(@build.artifacts_file, path)
        end

        def keep
          job.keep_artifacts!

          render json: job_json(job)
        end

        def destroy
          Ci::JobArtifacts::DeleteService.new(job).execute

          head :no_content
        end

        def expire_all
          Ci::JobArtifacts::DeleteProjectArtifactsService.new(project: @project).execute

          head :accepted
        end

        private

        def job
          @job ||= @project.builds.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          not_found!
        end

        def find_build_by_ref!
          @build = @project.latest_successful_build_for_ref(params[:job], params[:ref_name])
          not_found! unless @build
        end

        def require_artifacts!
          not_found! unless job.artifacts_file&.exists?
        end

        def require_available_artifacts!
          not_found! unless job.available_artifacts?
        end

        def require_artifacts_metadata!
          not_found! unless job.job_artifacts_metadata&.exists?
        end

        def require_artifacts_for_keep!
          not_found! unless job.artifacts?
        end

        def require_build_artifacts!
          not_found! unless @build.artifacts_file&.exists?
        end

        def job_json(build)
          {
            id: build.id,
            name: build.name,
            status: build.status,
            artifacts_expire_at: build.artifacts_expire_at
          }
        end

        def authorize_read_artifacts!
          forbidden! unless can?(current_user, :read_build, @project)
        end

        def authorize_destroy_artifacts!
          forbidden! unless can?(current_user, :delete_job_artifact, @project)
        end

        def authorize_update_artifacts!
          forbidden! unless can?(current_user, :update_build, @project)
        end
      end
    end
  end
end
