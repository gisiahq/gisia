# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class ApplicationController < BaseActionController
  include WorkhorseHelper

  protect_from_forgery with: :exception, prepend: true

  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :enforce_user_active!
  before_action :set_current_organization
  around_action :set_locale

  def render(*args, **options)
    options[:layout] = false if request.format.turbo_stream?
    super(*args, **options).tap do
      if (400..599).cover?(response.status) && workhorse_excluded_content_types.include?(response.media_type)
        response.headers['X-GitLab-Custom-Error'] = '1'
      end
    end
  end

  private

  def workhorse_excluded_content_types
    @workhorse_excluded_content_types ||= %w[text/html application/json text/vnd.turbo-stream.html]
  end

  def enforce_user_active!
    return if current_user.nil? || current_user.active?

    sign_out current_user
    flash[:alert] = blocked_account_reason(current_user)
    redirect_to new_user_session_path
  end

  def blocked_account_reason(user)
    case user.state
    when 'banned'
      _('Your account has been banned. Please contact an administrator.')
    else
      _('Your account is not active. Please contact an administrator.')
    end
  end

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
