# frozen_string_literal: true

module Projects
  module Settings
    class PipelinesController < Projects::Settings::ApplicationController
      layout 'project_settings'

      def update
        @pipeline_settings = project.pipeline_settings || project.build_pipeline_settings
        @ci_cd_settings = project.ci_cd_settings || project.build_ci_cd_settings

        if project.update(project_params)
          flash.now[:notice] = "Pipeline settings were successfully updated."
          respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.replace('general_pipelines_content', partial: 'projects/settings/pipelines/general_pipelines_content') }
            format.html { redirect_to edit_namespace_project_settings_ci_cd_path(project.namespace.parent.full_path, project.namespace.path) }
          end
        else
          flash.now[:alert] = "There was an error updating the pipeline settings."
          respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.replace('general_pipelines_content', partial: 'projects/settings/pipelines/general_pipelines_content') }
            format.html { redirect_to edit_namespace_project_settings_ci_cd_path(project.namespace.parent.full_path, project.namespace.path) }
          end
        end
      end

      private

      def project_params
        params.require(:project).permit(
          pipeline_settings_attributes: [:id, :auto_cancel_pending_pipelines, :ci_config_path, :build_allow_git_fetch, :build_timeout]
        )
      end
    end
  end
end
