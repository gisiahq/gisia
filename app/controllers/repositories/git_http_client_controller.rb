# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Repositories
  class GitHttpClientController < ::Repositories::ApplicationController
    include ActionController::HttpAuthentication::Basic
    include Gitlab::Utils::StrongMemoize

    attr_reader :authentication_result, :redirected_path

    delegate :authentication_abilities, to: :authentication_result, allow_nil: true
    delegate :type, to: :authentication_result, allow_nil: true, prefix: :auth_result

    skip_before_action :verify_authenticity_token
    prepend_before_action :authenticate_user, :parse_repo_path

    around_action :bypass_admin_mode!, if: :authenticated_user

    def authenticated_user
      authentication_result&.user || authentication_result&.deploy_token
    end

    private

    def user
      authenticated_user
    end

    def download_request?
      raise NotImplementedError
    end

    def upload_request?
      raise NotImplementedError
    end

    def authenticate_user
      @authentication_result = Gitlab::Auth::Result::EMPTY

      if basic_auth_provided?
        login, password = user_name_and_password(request)

        if handle_basic_authentication(login, password)
          return # Allow access
        end
      elsif http_download_allowed?

        @authentication_result = Gitlab::Auth::Result.new(nil, project, :none, [:download_code])

        return # Allow access
      end

      send_challenges
      render_access_denied
    rescue Gitlab::Auth::MissingPersonalAccessTokenError
      render_access_denied
    end

    def render_access_denied
      # Todo,

      render(
        plain: format(
          "HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped. "
        ),
        status: :unauthorized
      )
    end

    def basic_auth_provided?
      has_basic_credentials?(request)
    end

    def allow_basic_auth?
      true
    end

    def send_challenges
      challenges = []
      challenges << 'Basic realm="GitLab"' if allow_basic_auth?
      headers['Www-Authenticate'] = challenges.join("\n") if challenges.any?
    end

    def container
      parse_repo_path unless defined?(@container)

      @container
    end

    def project
      parse_repo_path unless defined?(@project)

      @project
    end

    def repository_path
      @repository_path ||= params[:repository_path]
    end

    def parse_repo_path
      @container, @project, @repo_type, @redirected_path = Gitlab::RepoPath.parse(repository_path)
    end

    def repository
      strong_memoize(:repository) do
        repo_type.repository_for(container)
      end
    end

    def repo_type
      parse_repo_path unless defined?(@repo_type)

      @repo_type
    end

    def handle_basic_authentication(login, password)
      @authentication_result = Gitlab::Auth.find_for_git_client(
        login, password, project: project, request: request
      )

      @authentication_result.success?
    end

    def ci?
      authentication_result.ci?(project)
    end

    def http_download_allowed?
      Gitlab::ProtocolAccess.allowed?('http') &&
        download_request? &&
        container &&
        ::Users::Anonymous.can?(repo_type.guest_read_ability, container)
    end

    def bypass_admin_mode!(&)
      return yield unless Gitlab::CurrentSettings.admin_mode

      Gitlab::Auth::CurrentUserMode.bypass_session!(authenticated_user.id, &)
    end
  end
end

Repositories::GitHttpClientController.prepend_mod_with('Repositories::GitHttpClientController')
