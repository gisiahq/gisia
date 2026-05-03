class ApplicationController < ActionController::Base
  include WorkhorseHelper

  allow_browser versions: :modern
  before_action :authenticate_user!
  around_action :set_locale

  private

  def set_locale(&block)
    if current_user
      Gitlab::I18n.with_user_locale(current_user, &block)
    else
      Gitlab::I18n.with_default_locale(&block)
    end
  end

  def can?(user, action, subject = :global)
    Ability.allowed?(user, action, subject)
  end

  def unauthorized!
    respond_to do |format|
      format.html { redirect_to new_user_session_path }
      format.any { head :unauthorized }
    end
  end

  def forbidden!
    respond_to do |format|
      format.html { head :forbidden }
      format.any { head :forbidden }
    end
  end

  def render_404
    respond_to do |format|
      format.html { render file: Rails.root.join("public/404.html"), status: :not_found, layout: false }
      format.js { render json: '', status: :not_found, content_type: 'application/json' }
      format.any { head :not_found }
    end
  end

  def permitted_param(key)
    params.permit(key)[key]
  end
end
