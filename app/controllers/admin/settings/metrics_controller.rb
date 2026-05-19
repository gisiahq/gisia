# frozen_string_literal: true

class Admin::Settings::MetricsController < Admin::ApplicationController
  def show
    @application_setting = ApplicationSetting.current_without_cache
  end

  def update
    @application_setting = ApplicationSetting.current_without_cache
    if @application_setting.update(metrics_params)
      redirect_to admin_settings_metrics_path, notice: _('Settings saved.')
    else
      render :show
    end
  end

  private

  def metrics_params
    params.require(:application_setting).permit(:version_check_enabled)
  end
end
