# frozen_string_literal: true

resources :issues, param: :iid, constraints: { iid: /\d+/ } do
  collection do
    get :search_users
    get :search_epics
  end
  member do
    patch :close
    patch :reopen
    post :move_stage
    patch :link_labels
    delete :unlink_label
    get :search_labels
    post :search_links
  end
  resources :links, only: [:create, :destroy], controller: 'issues/links'
end