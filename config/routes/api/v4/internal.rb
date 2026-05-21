# config/routes/api_internal.rb

namespace :internal do
  scope module: :ssh do
    get 'check'
    get 'authorized_keys'
    get 'discover'
    post 'allowed'
    post 'pre_receive'
    post 'post_receive'
    post 'lfs_authenticate'
  end

  namespace :workhorse do
    post 'authorize_upload'
  end
end
