# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: '*namespace_id/-',
    constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex },
    module: :namespaces,
    as: :namespace) do
    get 'skills.md', to: 'skills#group_skill', format: false, as: :skills_md
    get 'members/skill.md', to: 'skills#members', format: false, as: :members_skill_md
    get 'labels/skill.md', to: 'skills#labels', format: false, as: :labels_skill_md

    namespace :settings do
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

      resources :runners, only: [:index, :new, :create, :edit, :update, :destroy] do
        member do
          get :register
          post :pause
          post :resume
        end
      end

      resource :ci_cd, only: [:update], controller: 'ci_cd'
    end
  end

  get '*namespace_id', to: 'namespaces/namespaces#show', as: :namespace_show,
    constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }
end

constraints(::Constraints::UserUrlConstrainer.new) do
  get '*namespace_id', to: 'namespaces/namespaces#show',
    constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }
end
