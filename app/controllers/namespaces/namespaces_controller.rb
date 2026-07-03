# frozen_string_literal: true

class Namespaces::NamespacesController < Namespaces::ApplicationController
  layout :resolve_layout

  def show
    projects = if user_signed_in?
                 current_user.visible_projects_in_namespace(@namespace)
               else
                 @namespace.public_descendant_projects
               end
    @projects = projects.order(id: :desc)
  end

  private

  def resolve_layout
    @namespace&.group_namespace? ? 'namespace' : 'dashboard'
  end
end
