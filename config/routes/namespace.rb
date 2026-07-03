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
    namespace :settings do
      resources :members, only: [:index, :create, :update, :destroy] do
        collection do
          post :new_form
        end
        member do
          post :edit_form
        end
      end
    end
  end

  get '*namespace_id', to: 'namespaces/namespaces#show', as: :namespace_show,
    constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }
end

constraints(::Constraints::UserUrlConstrainer.new) do
  get '*namespace_id', to: 'namespaces/namespaces#show',
    constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }
end
