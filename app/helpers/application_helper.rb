# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module ApplicationHelper
  def can_admin_group?(group)
    current_user&.admin? || group.members.with_user(current_user).with_at_least_access_level(Accessible::MAINTAINER).exists?
  end

  def can_destroy_group?(group)
    current_user&.admin? || group.members.with_user(current_user).with_at_least_access_level(Accessible::OWNER).exists?
  end

  def can_admin_project?(project)
    current_user&.admin? || project.team.member?(current_user, Accessible::MAINTAINER)
  end

  def can_destroy_project?(project)
    current_user&.admin? || project.team.member?(current_user, Accessible::OWNER)
  end

  def locale_path
    asset_path("locale/#{Gitlab::I18n.locale}/app.js")
  end

  def format_datetime(time, user = nil, format: :long)
    return unless time

    tz = local_timezone_instance(user&.timezone)
    l(time.in_time_zone(tz), format: format)
  end

  def key_form_url(key)
    key.new_record? ? users_settings_keys_path : users_settings_key_path(key)
  end

  def strip_markdown(text)
    return '' if text.blank?

    strip_tags(text)
      .gsub(/[*_`#\[\]()>-]/, '')
      .squeeze(' ')
      .strip
  end

  def sidebar_section_active?(section)
    section_controllers = sidebar_section_config[section.to_sym]
    return false unless section_controllers

    section_controllers.include?(controller_path)
  end

  def sidebar_item_active?(section, item)
    item_config = sidebar_item_config["#{section}_#{item}".to_sym]
    return false unless item_config

    controller_matches?(item_config[:controller]) ||
      (item_config[:route_check] && current_page?(send(item_config[:route_check])))
  end

  private

  def sidebar_section_config
    {
      plan: %w[projects/issues projects/epics projects/boards],
      repository: %w[projects projects/merge_requests projects/branches projects/tags projects/commits projects/tree projects/blob],
      ci_cd: %w[projects/pipelines projects/jobs projects/ci_lint]
    }
  end

  def sidebar_item_config
    {
      plan_boards: {
        controller: 'projects/boards',
        route_check: :namespace_project_boards_path_check
      },
      plan_issues: {
        controller: 'projects/issues',
        route_check: :project_issues_path_check
      },
      plan_epics: {
        controller: 'projects/epics',
        route_check: :namespace_project_epics_path_check
      },
      repository_repository: {
        controller: ['projects', 'projects/tree', 'projects/blob'],
        route_check: :namespace_project_path_check
      },
      repository_merge_requests: {
        controller: 'projects/merge_requests',
        route_check: :namespace_project_merge_requests_path_check
      },
      repository_branches: {
        controller: 'projects/branches',
        route_check: :namespace_project_branches_path_check
      },
      repository_tags: {
        controller: 'projects/tags',
        route_check: :namespace_project_tags_path_check
      },
      ci_cd_pipelines: {
        controller: 'projects/pipelines',
        route_check: :pipelines_path_check
      },
      ci_cd_jobs: {
        controller: 'projects/jobs',
        route_check: :namespace_project_jobs_path_check
      },
      ci_cd_ci_lint: {
        controller: 'projects/ci_lint',
        route_check: :ci_lint_path_check
      }
    }
  end

  def controller_matches?(expected_controller)
    if expected_controller.is_a?(Array)
      expected_controller.include?(controller_path)
    else
      controller_path == expected_controller
    end
  end

  def namespace_project_boards_path_check
    namespace_project_boards_path(@project.namespace.parent.full_path, @project.path)
  end

  def project_issues_path_check
    project_issues_path(@project)
  end

  def namespace_project_epics_path_check
    namespace_project_epics_path(@project.namespace.parent.full_path, @project.namespace.path)
  end

  def namespace_project_path_check
    namespace_project_path(@project.namespace.parent.full_path, @project.namespace.path)
  end

  def namespace_project_merge_requests_path_check
    namespace_project_merge_requests_path(@project.namespace.parent.full_path, @project.namespace.path)
  end

  def namespace_project_branches_path_check
    namespace_project_branches_path(@project.namespace.parent.full_path, @project.namespace.path)
  end

  def namespace_project_tags_path_check
    namespace_project_tags_path(@project.namespace.parent.full_path, @project.namespace.path)
  end

  def pipelines_path_check
    pipelines_path(@project)
  end

  def namespace_project_jobs_path_check
    namespace_project_jobs_path(@project.namespace.parent.full_path, @project.namespace.path)
  end

  def ci_lint_path_check
    ci_lint_path(@project)
  end

  def user_homepage_path(user)
    namespace_show_path(user.username)
  end

end

