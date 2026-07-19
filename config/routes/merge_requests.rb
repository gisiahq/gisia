# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

resources :merge_requests, except: [:destroy], param: :iid, constraints: { iid: /\d+/ } do
  collection do
    get :search_users
  end
  member do
    get :show
    get :commits
    get :diffs
    get :expand_diff_lines
    get :pipelines
    post :run_pipeline
    post :merge
    post :search_links
    patch :link_labels
    delete :unlink_label
    get :search_labels
  end
  resources :links, only: [:create, :destroy], controller: 'merge_requests/links'

  resources :diff_notes, only: [:create]

  resources :draft_notes, only: [:create, :update, :destroy] do
    collection do
      post :publish
      delete :discard
    end
  end
end
