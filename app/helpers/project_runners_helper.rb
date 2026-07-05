# frozen_string_literal: true

module ProjectRunnersHelper
  def project_runners_path(project)
    namespace_project_settings_runners_path(project.namespace.parent.full_path, project.namespace.path)
  end

  def new_project_runner_path(project)
    new_namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path)
  end

  def edit_project_runner_path(project, runner)
    edit_namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path, runner)
  end

  def project_runner_path(project, runner)
    namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path, runner)
  end

  def register_project_runner_path(project, runner)
    register_namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path, runner)
  end

  def pause_project_runner_path(project, runner)
    pause_namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path, runner)
  end

  def resume_project_runner_path(project, runner)
    resume_namespace_project_settings_runner_path(project.namespace.parent.full_path, project.namespace.path, runner)
  end
end
