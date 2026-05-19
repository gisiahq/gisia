# frozen_string_literal: true

class Namespaces::NamespacesController < Namespaces::ApplicationController
  def show
    projects = if user_signed_in?
                 current_user.visible_projects_in_namespace(@namespace)
               else
                 @namespace.descendant_projects.joins(:namespace).where(namespaces: { visibility_level: Gitlab::VisibilityLevel::PUBLIC })
               end
    @projects = projects.order(id: :desc)
  end
end
