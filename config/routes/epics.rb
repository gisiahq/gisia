# frozen_string_literal: true

resources :epics, param: :iid, constraints: { iid: /\d+/ } do
  collection do
    get :search_users
    get :search_epics
  end
  member do
    patch :close
    patch :reopen
    get :search_labels
    patch :link_labels
    delete :unlink_label
  end
end