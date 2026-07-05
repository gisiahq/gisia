# frozen_string_literal: true

class Namespaces::SkillsController < Namespaces::ApplicationController
  include Gitlab::Auth::AuthFinders

  def group_skill
    render_404 unless @namespace&.group_namespace?

    render formats: [:text], content_type: 'text/markdown', layout: false
  end

  private

  def current_user
    @current_user ||= begin
      find_user_from_access_token
    rescue Gitlab::Auth::AuthenticationError
      nil
    end || super
  end
end
