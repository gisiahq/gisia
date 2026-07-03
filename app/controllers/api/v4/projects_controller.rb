# frozen_string_literal: true

module API
  module V4
    class ProjectsController < ::API::V4::UserBaseController
      include API::V4::ProjectFindable
      include ::Projects::Parameterizable
      include VerifiesParentNamespace

      before_action :find_project!, only: [:show, :update, :destroy]
      before_action :verify_parent_namespace!, only: [:create]
      before_action -> { authorize_project!(:admin_project) }, only: [:update]
      before_action -> { authorize_project!(:remove_project) }, only: [:destroy]

      def index
        projects = Project.where(id: current_user.projects)
        projects = projects.search(params[:search]) if params[:search].present?
        @projects = paginate(projects.order(id: :desc))
      end

      def show; end

      def create
        @project = Project.new(create_params.merge(creator_id: current_user.id))
        if @project.save
          render :show, status: :created
        else
          render json: { message: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @project.update(update_params)
          render :show
        else
          render json: { message: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @project.destroy!
        head :no_content
      end

      private

      def authorize_project!(ability)
        forbidden! unless Ability.allowed?(current_user, ability, @project)
      end

      def update_params
        params.permit(:name, :description, :visibility_level).compact
      end

      def requested_parent_namespace_id
        create_params[:namespace_parent_id]
      end
    end
  end
end
