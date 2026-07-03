# frozen_string_literal: true

class Namespaces::Settings::ApplicationController < Namespaces::ApplicationController
  layout 'namespace_settings'

  before_action :require_group_namespace!
  before_action :authorize_settings_access!

  private

  def require_group_namespace!
    render_404 unless @namespace.is_a?(Namespaces::GroupNamespace)
  end

  def authorize_settings_access!
    return if current_user&.admin?
    return if current_user && settings_access_level >= Accessible::MAINTAINER

    head :forbidden
  end

  def settings_access_level
    @settings_access_level ||= current_user.max_member_access_for_namespace(@namespace)
  end
end
