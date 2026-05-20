# frozen_string_literal: true

module Projects
  module Settings
    class MergeRequestsController < Projects::Settings::ApplicationController
      layout 'project_settings'

      def edit
        @namespace_settings = project.namespace.namespace_settings || project.namespace.build_namespace_settings
      end

      def update
        @namespace_settings = project.namespace.namespace_settings || project.namespace.create_namespace_settings!

        if @namespace_settings.update(merge_requests_settings_params)
          flash.now[:notice] = "Merge request settings were successfully updated."
        else
          flash.now[:alert] = "There was an error updating the merge request settings."
        end

        render turbo_stream: [
          turbo_stream.replace('flash', partial: 'shared/flash'),
          turbo_stream.replace('merge_options_content', partial: 'projects/settings/merge_requests/merge_options_content')
        ]
      end

      private

      def merge_requests_settings_params
        @merge_requests_settings_params ||= params.require(:namespace_setting).permit(:squash_enabled, :remove_source_branch_after_merge)
      end
    end
  end
end
