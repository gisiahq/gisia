# frozen_string_literal: true

module Namespaces
  module Settings
    class RunnersController < Namespaces::Settings::ApplicationController
      include RunnerListable

      before_action :authorize_admin_group_runners!, except: [:index]
      before_action :set_runner, only: [:edit, :update, :destroy, :register, :pause, :resume]

      def index
        filter_runner_list(available_runners, owner_namespace_id: @namespace.id)
        @ancestor_shared_runners_disabled = @namespace.ancestor_shared_runners_disabled?
      end

      def new
        @runner = ::Ci::Runner.new(runner_type: :group_type)
      end

      def create
        @runner = ::Ci::Runner.new(runner_type: :group_type, registration_type: :authenticated_user)
        @runner.assign_attributes(runner_params)
        @runner.runner_namespaces.build(namespace_id: @namespace.id)

        if @runner.save
          redirect_to register_namespace_settings_runner_path(@namespace.full_path, @runner),
            notice: _('Runner created. Please register it.')
        else
          flash.now[:alert] = @runner.errors.full_messages.join(', ')
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @runner.update(runner_params)
          redirect_to namespace_settings_runners_path(@namespace.full_path), notice: _('Runner was successfully updated.')
        else
          flash.now[:alert] = @runner.errors.full_messages.join(', ')
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @runner.destroy
        redirect_to namespace_settings_runners_path(@namespace.full_path), notice: _('Runner was successfully deleted.')
      end

      def register
        render_404 unless @runner.registration_available?
      end

      def pause
        @runner.update(active: false)
        redirect_to namespace_settings_runners_path(@namespace.full_path), notice: _('Runner paused.')
      end

      def resume
        @runner.update(active: true)
        redirect_to namespace_settings_runners_path(@namespace.full_path), notice: _('Runner resumed.')
      end

      private

      # Runners available to this group: group runners of this group and its ancestors,
      # plus instance runners when they are enabled for this group.
      def available_runners
        runners = ::Ci::Runner.group_type.belonging_to_namespaces(@namespace.traversal_ids)
        return runners if @namespace.shared_runners_disabled?

        ::Ci::Runner.from_union([runners, ::Ci::Runner.instance_type])
      end

      # Only this group's own runners can be managed here (not ancestor or instance runners).
      def owned_runners
        ::Ci::Runner.group_type.belonging_to_namespaces([@namespace.id])
      end

      def set_runner
        @runner = owned_runners.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to namespace_settings_runners_path(@namespace.full_path), alert: _('Runner not found')
      end

      def authorize_admin_group_runners!
        head :forbidden unless can?(current_user, :admin_group_runners, @namespace)
      end

      def runner_params
        @runner_params ||= params.require(:runner).permit(:description, :run_untagged, :maximum_timeout).merge(
          tag_list: params.dig(:runner, :tags).to_s.split(',').map(&:strip),
          active: params.dig(:runner, :paused) != "1"
        )
      end
    end
  end
end
