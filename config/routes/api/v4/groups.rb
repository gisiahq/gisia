resources :groups, only: [:index, :show, :create, :update, :destroy] do
  resources :members, only: [:index, :show, :create, :update, :destroy], param: :user_id, controller: 'groups/members'
end
