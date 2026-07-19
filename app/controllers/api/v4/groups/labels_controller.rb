# frozen_string_literal: true

module API
  module V4
    module Groups
      class LabelsController < ::API::V4::UserBaseController
        before_action :find_group!
        before_action :set_label, only: [:show, :update, :destroy]
        before_action :authorize_read_label!, only: [:index, :show]
        before_action :authorize_admin_label!, only: [:create, :update, :destroy]

        def index
          labels = @namespace.labels
          labels = labels.search_by_title(params[:search]) if params[:search].present?
          @labels = paginate(labels.order(title: :asc))
        end

        def show; end

        def create
          @label = @namespace.labels.build(create_params)

          if @label.save
            render :show, status: :created
          else
            render json: { message: @label.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @label.update(update_params)
            render :show
          else
            render json: { message: @label.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @label.destroy
          head :no_content
        end

        private

        def find_group!
          ns = Namespace.without_project_namespaces.find_by_id_or_path(params[:group_id])
          not_found! unless ns&.group_namespace?

          @namespace = ns
        end

        def authorize_read_label!
          forbidden! unless current_user.can?(:read_label, @namespace)
        end

        def authorize_admin_label!
          forbidden! unless current_user.can?(:admin_label, @namespace)
        end

        def set_label
          @label = @namespace.labels.find_by(id: params[:id])
          not_found! unless @label
        end

        def create_params
          params.permit(:title, :color, :description, :rank)
        end

        def update_params
          params.permit(:title, :color, :description, :rank)
        end
      end
    end
  end
end
