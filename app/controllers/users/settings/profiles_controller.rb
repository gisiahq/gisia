module Users
  module Settings
    class ProfilesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_user

      def show; end

      def edit; end

      def update
        if @user.update(profile_params)
          redirect_to users_settings_profile_path, notice: 'Profile updated successfully.'
        else
          render :update
        end
      end

      private

      def set_user
        @user = current_user
      end

      def profile_params
        params.require(:user).permit(:email, :username, :name, :avatar, :timezone, :preferred_language)
      end
    end
  end
end
