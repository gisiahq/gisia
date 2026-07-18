# frozen_string_literal: true

module Namespaces
  module Settings
    class LabelsController < Namespaces::Settings::ApplicationController
      skip_before_action :authorize_settings_access!
      before_action :authorize_read_labels!, only: [:index, :new_form]
      before_action :set_label, only: [:edit_form, :update, :destroy]
      before_action :authorize_read_labels!, only: [:edit_form]
      before_action :authorize_admin_labels!, only: [:create, :update, :destroy]

      def index
        @labels = @namespace.labels.order(id: :desc)

        respond_to do |format|
          format.html
          format.turbo_stream { render :index }
        end
      end

      def new_form
        @label = @namespace.labels.build

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
        @label = @namespace.labels.build(label_params)

        if @label.save
          @labels = @namespace.labels.order(id: :desc)

          respond_to do |format|
            format.turbo_stream { render :create }
            format.html { redirect_to labels_page_path, notice: 'Label was successfully created.' }
          end
        else
          render :new_form, status: :unprocessable_entity
        end
      end

      def update
        if @label.update(label_params)
          respond_to do |format|
            format.turbo_stream { render :update }
            format.html { redirect_to labels_page_path, notice: 'Label was successfully updated.' }
          end
        else
          render :edit_form, status: :unprocessable_entity
        end
      end

      def destroy
        @label.destroy

        respond_to do |format|
          format.turbo_stream { render :destroy }
          format.html { redirect_to labels_page_path, notice: 'Label was successfully deleted.' }
        end
      end

      private

      def authorize_read_labels!
        head :forbidden unless current_user&.can?(:read_label, @namespace)
      end

      def authorize_admin_labels!
        head :forbidden unless current_user&.can?(:admin_label, @namespace)
      end

      def set_label
        @label = @namespace.labels.find(params[:id])
      end

      def labels_page_path
        namespace_settings_labels_path(@namespace.full_path)
      end

      def label_params
        @label_params ||= params.require(:label).permit(:title, :description, :color, :rank)
      end
    end
  end
end
