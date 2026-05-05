resources :projects, only: [:index, :show, :create, :update, :destroy] do
  resources :issues, only: [:index, :show, :create, :update, :destroy], param: :issue_iid, controller: 'projects/issues'
  resources :labels, only: [:index, :show, :create, :update, :destroy], controller: 'projects/labels'
  resources :epics, only: [:index, :show, :create, :update, :destroy], param: :epic_iid, controller: 'projects/epics' do
    member do
      get :issues, controller: 'projects/epic_issues', action: :index
    end
  end
  resources :members, only: [:index, :show, :create, :update, :destroy], param: :user_id, controller: 'projects/members'
  resources :merge_requests, only: [:index, :show, :create, :update, :destroy],
    param: :merge_request_iid, controller: 'projects/merge_requests'
  resources :pipelines, only: [:index, :show, :create, :destroy], controller: 'projects/pipelines' do
    member do
      post :retry
      post :cancel
      get :jobs, controller: 'projects/jobs', action: :pipeline_jobs
    end
  end
  resources :jobs, only: [:index, :show], controller: 'projects/jobs' do
    member do
      get :trace
      post :retry
      post :cancel
    end
  end
  get 'repository/branches', to: 'projects/branches#index', as: :repository_branches
  post 'repository/branches', to: 'projects/branches#create'
  constraints(name: %r{[^/]+}) do
    get 'repository/branches/:name', to: 'projects/branches#show', as: :repository_branch
    match 'repository/branches/:name', to: 'projects/branches#check', via: :head
    delete 'repository/branches/:name', to: 'projects/branches#destroy'
  end
  get 'repository/tags', to: 'projects/tags#index', as: :repository_tags
  post 'repository/tags', to: 'projects/tags#create'
  constraints(name: %r{[^/]+}) do
    get 'repository/tags/:name', to: 'projects/tags#show', as: :repository_tag
    delete 'repository/tags/:name', to: 'projects/tags#destroy'
  end
end
