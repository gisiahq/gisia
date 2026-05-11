# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(
    path: '*namespace_id',
    as: :namespace,
    namespace_id: Gitlab::PathRegex.full_namespace_route_regex
  ) do
    scope(
      path: ':project_id',
      constraints: { project_id: Gitlab::PathRegex.project_route_regex },
      module: :projects,
      as: :project
    ) do
      scope '-' do
        get 'skill.md', to: 'skills#project_skill', format: false, as: :project_skill_md
        get 'issues/skill.md', to: 'skills#issues', format: false, as: :issues_skill_md
        get 'epics/skill.md', to: 'skills#epics', format: false, as: :epics_skill_md
        get 'labels/skill.md', to: 'skills#labels', format: false, as: :labels_skill_md
        get 'branches/skill.md', to: 'skills#branches', format: false, as: :branches_skill_md
        get 'tags/skill.md', to: 'skills#tags', format: false, as: :tags_skill_md
        get 'merge_requests/skill.md', to: 'skills#merge_requests', format: false, as: :merge_requests_skill_md
        get 'pipelines/skill.md', to: 'skills#pipelines', format: false, as: :pipelines_skill_md
        get 'jobs/skill.md', to: 'skills#jobs', format: false, as: :jobs_skill_md
        get 'members/skill.md', to: 'skills#members', format: false, as: :members_skill_md

        get 'ci/lint', to: 'ci_lint#show', as: :ci_lint
        post 'ci/lint/validate', to: 'ci_lint#validate', as: :validate_ci_lint

        draw :repository
        draw :merge_requests
        draw :pipelines
        draw :jobs
        draw :issues
        draw :epics
        draw :boards

        resources :uploads, only: [:create] do
          collection do
            get ":secret/:filename", action: :show, as: :show, constraints: { filename: %r{[^/]+} }, format: false, defaults: { format: nil }
            post :authorize
          end
        end

        # Notes routes
        resources :notes, only: [:show, :create, :edit, :update, :destroy] do
          member do
            post :replies
            post :resolve
            delete :resolve, action: :unresolve
            post :expand
            post :collapse
            post :edit_form, action: :edit
            post :show_form, action: :show
          end
        end


        namespace :settings do
          resource :repository, only: [:edit, :update], controller: 'repository'
          resource :merge_requests, only: [:edit, :update], controller: 'merge_requests'
          resource :ci_cd, only: [:edit], controller: 'ci_cd'
          resource :pipelines, only: [:update], controller: 'pipelines'
          resources :variables, only: [:create, :update, :destroy], controller: 'variables'
          resources :protected_branches, only: [:index, :show, :edit, :create, :update, :destroy]
          resources :protected_tags, only: [:index, :show, :create, :update, :destroy]
          resources :members, only: [:index, :create, :update, :destroy] do
            collection do
              post :new_form
            end
            member do
              post :edit_form
            end
          end
          resources :labels, only: [:index, :create, :update, :destroy] do
            collection do
              post :new_form
            end
            member do
              post :edit_form
            end
          end
          resources :webhooks, only: [:index, :create, :update, :destroy] do
            collection do
              post :new_form
            end
            member do
              post :edit_form
            end
          end
        end
      end
    end
    resources(
      :projects,
      path: '/',
      constraints: { id: Gitlab::PathRegex.project_route_regex },
      only: %i[edit show update destroy]
    ) do
    end
  end
end
