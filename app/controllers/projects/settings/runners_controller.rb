# frozen_string_literal: true

module Projects
  module Settings
    class RunnersController < Projects::Settings::ApplicationController
      include RunnerListable

      layout 'project_settings'

      before_action :set_runner, only: [:edit, :update, :destroy, :register, :pause, :resume]

      def index
        filter_runner_list(project.all_available_runners, owner_namespace_id: project.namespace.id)
        @namespace_settings = project.namespace.namespace_settings
        @ci_cd_settings = project.ci_cd_settings || project.build_ci_cd_settings
        @ancestor_shared_runners_disabled = project.namespace.ancestor_shared_runners_disabled?
      end

      def settings
        if settings_params.key?(:shared_runners_enabled)
          namespace_settings = project.namespace.namespace_settings || project.namespace.build_namespace_settings
          namespace_settings.update(shared_runners_enabled: settings_params[:shared_runners_enabled] == '1')
        end

        if settings_params.key?(:group_runners_enabled)
          ci_cd_settings = project.ci_cd_settings || project.build_ci_cd_settings
          ci_cd_settings.update(group_runners_enabled: settings_params[:group_runners_enabled] == '1')
        end

        redirect_to runners_path, notice: _('Runner settings were successfully updated.')
      end

      def new
        @runner = ::Ci::Runner.new(runner_type: :project_type)
      end

      def create
        @runner = ::Ci::Runner.new(runner_type: :project_type, registration_type: :authenticated_user)
        @runner.assign_attributes(runner_params)
        @runner.runner_namespaces.build(namespace_id: project.namespace.id)

        if @runner.save
          redirect_to register_runner_path(@runner), notice: _('Runner created. Please register it.')
        else
          flash.now[:alert] = @runner.errors.full_messages.join(', ')
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @runner.update(runner_params)
          redirect_to runners_path, notice: _('Runner was successfully updated.')
        else
          flash.now[:alert] = @runner.errors.full_messages.join(', ')
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @runner.destroy
        redirect_to runners_path, notice: _('Runner was successfully deleted.')
      end

      def register
        render_404 unless @runner.registration_available?
      end

      def pause
        @runner.update(active: false)
        redirect_to runners_path, notice: _('Runner paused.')
      end

      def resume
        @runner.update(active: true)
        redirect_to runners_path, notice: _('Runner resumed.')
      end

      private

      def project_runners
        ::Ci::Runner.project_type.belonging_to_namespaces([project.namespace.id])
      end

      def set_runner
        @runner = project_runners.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to runners_path, alert: _('Runner not found')
      end

      def runners_path
        namespace_project_settings_runners_path(project.namespace.parent.full_path, project.namespace.path)
      end

      def register_runner_path(runner)
        register_namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path, runner)
      end

      def runner_params
        @runner_params ||= params.require(:runner).permit(:description, :run_untagged, :maximum_timeout).merge(
          tag_list: params.dig(:runner, :tags).to_s.split(',').map(&:strip),
          active: params.dig(:runner, :paused) != "1"
        )
      end

      def settings_params
        @settings_params ||= params.permit(:shared_runners_enabled, :group_runners_enabled)
      end
    end
  end
end
