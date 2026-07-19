# frozen_string_literal: true

class Namespaces::SkillsController < Namespaces::ApplicationController
  include Gitlab::Auth::AuthFinders

  before_action :require_group_namespace!

  def group_skill
    render formats: [:text], content_type: 'text/markdown', layout: false
  end

  def members
    render formats: [:text], content_type: 'text/markdown', layout: false
  end

  def labels
    render formats: [:text], content_type: 'text/markdown', layout: false
  end

  private

  def require_group_namespace!
    render_404 unless @namespace&.group_namespace?
  end

  def current_user
    @current_user ||= begin
      find_user_from_access_token
    rescue Gitlab::Auth::AuthenticationError
      nil
    end || super
  end
end
