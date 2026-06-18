class Dashboard::HomeController < Dashboard::ApplicationController
  def home
    if current_user.projects.exists?
      @projects = order_pinned_first(current_user.projects)
      render 'dashboard/projects/index'
    else
      @username = current_user.name
    end
  end
end
