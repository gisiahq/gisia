class Dashboard::HomeController < Dashboard::ApplicationController
  def home
    if current_user.authorized_projects.exists?
      @projects = order_pinned_first(current_user.authorized_projects).page(params[:page]).per(20)
      render 'dashboard/projects/index'
    else
      @username = current_user.name
    end
  end
end
