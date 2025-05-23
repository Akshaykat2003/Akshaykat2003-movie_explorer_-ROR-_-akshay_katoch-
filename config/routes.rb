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
      get    'movies/all',   to: 'movies#all'
      get    'movies/:id',   to: 'movies#show'
      post   'movies',       to: 'movies#create'
      patch  'movies/:id',   to: 'movies#update'  
      delete 'movies/:id',   to: 'movies#destroy'

      get    'subscriptions',                  to: 'subscriptions#index'
      post   'subscriptions',                  to: 'subscriptions#create'
      get    'subscriptions/success',          to: 'subscriptions#success'
      get    'subscriptions/cancel',           to: 'subscriptions#cancel'
      get    'subscriptions/check_status', to: 'subscriptions#check_subscription_status'
      post   'subscriptions/confirm_payment',  to: 'subscriptions#confirm_payment'

      get    'wishlist', to: 'wishlists#index'
      post   'wishlist', to: 'wishlists#create'
      delete 'wishlist/:movie_id', to: 'wishlists#destroy'
    end
  end

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
end