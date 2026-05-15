resources :jobs, only: %i[create update] do
  collection do
    post :request, action: :job_request
  end

  member do
    patch :trace
    post 'artifacts/authorize', action: :authorize_artifact
    post :artifacts, action: :create_artifact
    get :artifacts, action: :download_artifact
  end
end

