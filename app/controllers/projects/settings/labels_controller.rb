module Projects
  module Settings
    class LabelsController < Projects::Settings::ApplicationController
      include LabelsHelper
      before_action :authorize_read_labels!, only: [:index, :new_form, :new]
      before_action :authorize_admin_label!, only: [:create]
      before_action :set_label, only: [:edit_form, :update, :destroy]
      before_action :authorize_read_label!, only: [:edit_form]
      before_action :authorize_update_label!, only: [:update]
      before_action :authorize_destroy_label!, only: [:destroy]

      def index
        @labels = @project.namespace.labels.order(id: :desc)

        respond_to do |format|
          format.html
          format.turbo_stream { render :index }
        end
      end

      def new_form
        @label = @project.namespace.labels.build

        respond_to do |format|
          format.html
          format.turbo_stream { render :new_form }
        end
      end

      def edit_form
        respond_to do |format|
          format.html
          format.turbo_stream { render :edit_form }
        end
      end

      def create
        @label = @project.namespace.labels.build(label_params)

        if @label.save
          @labels = @project.namespace.labels.order(id: :desc)

          respond_to do |format|
            format.turbo_stream { render :create }
            format.html { redirect_to labels_path(@project), notice: 'Label was successfully created.' }
          end
        else
          render :new_form, status: :unprocessable_entity
        end
      end

      def update
        if @label.update(label_params)
          redirect_to labels_path(@project),
            notice: 'Label was successfully updated.'
        else
          render :edit_form, status: :unprocessable_entity
        end
      end

      def destroy
        @label.destroy

        respond_to do |format|
          format.turbo_stream { render :destroy }
          format.html { redirect_to labels_path(@project), notice: 'Label was successfully deleted.' }
        end
      end

      private

      def authorize_read_labels!
        head :forbidden unless current_user.can?(:read_label, @project)
      end

      def authorize_admin_label!
        head :forbidden unless current_user.can?(:admin_label, @project)
      end

      def authorize_read_label!
        head :forbidden unless current_user.can?(:read_label, @project)
      end

      def authorize_update_label!
        head :forbidden unless current_user.can?(:admin_label, @project)
      end

      def authorize_destroy_label!
        head :forbidden unless current_user.can?(:admin_label, @project)
      end

      def set_label
        @label = @project.namespace.labels.find(params[:id])
      end

      def label_params
        params.require(:label).permit(:title, :description, :color, :rank)
      end
    end
  end
end

