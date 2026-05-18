# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

namespace :admin do
  root 'dashboard#index'
  
  get 'dashboard', to: 'dashboard#index'
  resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :projects, only: [:index, :show, :edit, :update, :destroy]
  resources :groups, only: [:index, :show, :edit, :update, :destroy]
  
  resources :runners, only: %i[index new show edit create update destroy] do
    member do
      get :register
      post :resume
      post :pause
    end
  end
  
  namespace :settings do
    resource :privacy, only: [:show, :update], path: 'privacy', controller: 'privacy'
  end

  resources :jobs, only: [:index] do
    member do
      post :cancel
    end
    collection do
      post :cancel_all
      get :search_projects
    end
  end
end
