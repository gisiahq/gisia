# frozen_string_literal: true

module API
  module V4
    class UsersController < ::API::V4::UserBaseController
      before_action :require_admin!, only: %i[index create find_user update destroy block unblock create_personal_access_token]
      before_action :set_user!, only: %i[find_user update destroy block unblock]
      before_action :deny_user_deletion, only: :destroy

      def index
        @users = User.all
        @users = @users.where(username: params[:username]) if params[:username].present?
      end

      def show
      end

      def create
        @user = User.new(user_params)
        @user.skip_confirmation!

        if @user.save
          render :create, status: :created
        else
          render json: { message: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def find_user
      end

      def update
        if @user.update(user_params)
          render :update
        else
          render json: { message: @user.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        render json: { message: ['has already been taken'] }, status: :unprocessable_entity
      end

      def destroy
        @user.destroy
        head :no_content
      end

      def block
        if @user.block
          head :no_content
        else
          render json: { message: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def unblock
        if @user.activate
          head :no_content
        else
          render json: { message: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def create_personal_access_token
        user = User.find_by(id: params[:user_id])
        return not_found! unless user

        token = user.personal_access_tokens.new(pat_params)
        token.scopes = Array(params[:scopes])

        if token.save
          @token = token
          render 'api/v4/personal_access_tokens/create', status: :created
        else
          render json: { message: token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_user!
        @user = User.find_by(id: params[:id])
        not_found! unless @user
      end

      def deny_user_deletion
        render json: { message: 'User deletion is not implemented yet.' }, status: :not_implemented
      end

      def require_admin!
        forbidden! unless current_user.admin?
      end

      def user_params
        @user_params ||= params.permit(:email, :name, :username, :password, :admin)
      end

      def pat_params
        params.permit(:name, :description, :expires_at)
      end
    end
  end
end
