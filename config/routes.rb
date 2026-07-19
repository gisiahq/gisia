# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

Rails.application.routes.draw do
  use_doorkeeper
  mount MissionControl::Jobs::Engine, at: '/jobs'

  devise_for :users, skip: [:registrations]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  draw 'api/v4'

  root 'dashboard/home#home'
  scope path: '-' do
    namespace :dashboard do
      resources :projects, except: %i[edit show]
      resources :groups, except: %i[show]
      resources :pins, only: %i[create destroy]
    end

    draw 'users/settings'
    get 'users/skills.md', to: 'users/skills#show', format: false, as: :users_skills_md
    get 'users/personal_access_tokens/skill.md', to: 'users/skills#personal_access_tokens', format: false, as: :users_personal_access_tokens_skill_md
    draw :markdown
  end

  scope path: '-' do
    get '/:model/:model_id/uploads/:secret/:filename',
      to: 'banzai/uploads#show',
      constraints: { model: /project/, filename: %r{[^/]+} },
      as: :banzai_upload
  end

  draw :admin
  draw :project
  draw :namespace
  draw :git_http
end
