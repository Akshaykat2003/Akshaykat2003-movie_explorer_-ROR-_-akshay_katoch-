Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      post 'signup', to: 'users#signup'
      post 'login', to: 'users#login'
      post 'logout', to: 'users#logout'
      
      post 'update_preferences', to: 'users#update_preferences'
      post 'send_notification', to: 'notifications#send_fcm'

      get    'movies',       to: 'movies#index'
      get    'movies/:id',   to: 'movies#show'
      post   'movies',       to: 'movies#create'
      patch  'movies/:id',   to: 'movies#update'
      put    'movies/:id',   to: 'movies#update'
      delete 'movies/:id',   to: 'movies#destroy'

      get    'subscriptions',                  to: 'subscriptions#index' 
      post   'subscriptions',                  to: 'subscriptions#create'
      get    'subscriptions/success',          to: 'subscriptions#success'
      get    'subscriptions/cancel',           to: 'subscriptions#cancel'
      get    'subscriptions/:id/check_status', to: 'subscriptions#check_subscription_status'
    end
  end

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
end