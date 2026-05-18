# frozen_string_literal: true

class Admin::Settings::PrivacyController < Admin::ApplicationController
  def show
    @application_setting = ApplicationSetting.current_without_cache
  end

  def update
    @application_setting = ApplicationSetting.current_without_cache
    if @application_setting.update(privacy_params)
      redirect_to admin_settings_privacy_path, notice: _('Settings saved.')
    else
      render :show
    end
  end

  private

  def privacy_params
    params.require(:application_setting).permit(:version_check_enabled)
  end
end
