# frozen_string_literal: true

module Users
  module Settings
    class PersonalAccessTokensController < ApplicationController
      before_action :authenticate_user!

      def index
        @tokens = current_user.personal_access_tokens.order(created_at: :desc)
      end

      def new
        @token = PersonalAccessToken.new(expires_at: 30.days.from_now)
      end

      def create
        @token = current_user.personal_access_tokens.build(token_params)
        @token.scopes = token_params[:scopes]&.reject(&:blank?) || []

        if @token.save
          @new_token = @token.token
          @tokens = current_user.personal_access_tokens.order(created_at: :desc)
          respond_to do |format|
            format.turbo_stream { render :create }
            format.html { redirect_to users_settings_personal_access_tokens_path }
          end
        else
          respond_to do |format|
            format.turbo_stream { render :new, status: :unprocessable_entity }
            format.html { render :new, status: :unprocessable_entity }
          end
        end
      end

      def revoke
        @token = current_user.personal_access_tokens.find(params[:id])
        @token.revoke!
        redirect_to users_settings_personal_access_tokens_path, notice: "Revoked personal access token \"#{@token.name}\"."
      end

      private

      def token_params
        @token_params ||= params.require(:personal_access_token).permit(:name, :expires_at, :description, scopes: [])
      end
    end
  end
end
