module RoutesPatch
  def help_page_url(path = '', anchor: nil)
    "#"
  end

  def project_blob_url(project, id, **options)
    namespace_project_blob_url(project.namespace.parent.full_path, project.path, id, **options)
  end

  def project_raw_url(project, id, **options)
    namespace_project_raw_url(project.namespace.parent.full_path, project.path, id, **options)
  end
end

Rails.application.routes.url_helpers.extend(RoutesPatch)

