# frozen_string_literal: true

module ProjectsHelper
  def merge_request_user_search_path(mr)
    project = mr.target_project
    search_users_namespace_project_merge_requests_path(project.namespace.parent.full_path, project.path)
  end

  def merge_request_path(mr)
    project = mr.target_project
    namespace_project_merge_request_path(project.namespace.parent.full_path, project.path)
  end

  def project_breadcrumb_name(project)
    project.route.name.sub('/', '>')
  end

  def project_breadcrumb_nodes(project)
    names = project.route.name.split(' / ')
    paths = project.route.path.split('/')
    names.map.with_index do |name, i|
      if i == names.size - 1
        { label: name, path: project_path(project) }
      else
        { label: name, path: namespace_show_path(paths[0..i].join('/')) }
      end
    end
  end

  def project_path(_project)
    namespace_project_path(@project.namespace.parent.full_path, @project.path)
  end

  def pipelines_path(project)
    namespace = project.namespace.parent

    namespace_project_pipelines_path(namespace.full_path, project.path)
  end

  def new_pipeline_path(project)
    namespace = project.namespace.parent

    new_namespace_project_pipeline_path(namespace.full_path, project.path)
  end

  def pipeline_path(pipeline)
    project = pipeline.project
    namespace = project.namespace.parent

    namespace_project_pipeline_path(namespace.full_path, project.path, pipeline)
  end

  def pipeline_jobs_path(pipeline)
    project = pipeline.project
    namespace = project.namespace.parent

    jobs_namespace_project_pipeline_path(namespace.full_path, project.path, pipeline)
  end

  def job_path(job)
    project = job.project
    namespace = project.namespace.parent
    namespace_project_job_path(namespace.full_path, project.path, job)
  end

  def pipeline_title(pipeline)
    "Pipeline ##{pipeline.id}"
  end

  def pipeline_url(pipeline)
    project = pipeline.project
    namespace = project.namespace.parent

    namespace_project_pipeline_url(namespace.full_path, project.path, pipeline)
  end

  def job_url(job)
    project = job.project
    namespace = project.namespace.parent
    namespace_project_job_url(namespace.full_path, project.path, job)
  end

  def ci_lint_path(project)
    namespace = project.namespace.parent
    namespace_project_ci_lint_path(namespace.full_path, project.path)
  end

  def content_ci_lint_path(project)
    namespace = project.namespace.parent
    namespace_project_content_ci_lint_path(namespace.full_path, project.path)
  end

  def validate_ci_lint_path(project)
    namespace = project.namespace.parent
    namespace_project_validate_ci_lint_path(namespace.full_path, project.path)
  end

  def project_issues_path(project, options = {})
    namespace = project.namespace.parent
    namespace_project_issues_path(namespace.full_path, project.path, options)
  end

  def issue_path(issue)
    project = issue.project
    namespace = project.namespace.parent
    namespace_project_issue_path(namespace.full_path, project.path, issue)
  end

  def new_project_issue_path(project)
    namespace = project.namespace.parent
    new_namespace_project_issue_path(namespace.full_path, project.path)
  end

  unless method_defined?(:default_url_options)
    def default_url_options
      Rails.application.routes.default_url_options
    end
  end

  def history_link(project, ref, path, ref_type)
    namespace_project_commits_path(project.namespace.parent.full_path, project.path, "#{ref}/#{path}",
      ref_type: ref_type || 'HEADS')
  end

  def resolve_note_path(note)
    namespace = note.noteable.project.namespace
    resolve_namespace_project_note_path(namespace.parent.full_path, namespace.path, note)
  end

  def note_path(note)
    namespace = note.namespace
    namespace_project_note_path(namespace.parent.full_path, namespace.path, note)
  end

  def can_access_project_settings?(project, user)
    return false unless user

    user.admin? || project.team.member?(user, Accessible::MAINTAINER)
  end
end
