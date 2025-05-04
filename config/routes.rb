Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      post 'signup', to: 'users#signup'
      post 'login', to: 'users#login'

      # Custom routes for movies
      get 'movies', to: 'movies#index'          
      get 'movies/:id', to: 'movies#show'      
      post 'movies', to: 'movies#create'        
      patch 'movies/:id', to: 'movies#update'   
      put 'movies/:id', to: 'movies#update'     
      delete 'movies/:id', to: 'movies#destroy' 

      get 'subscriptions', to: 'subscriptions#index'
      get 'subscriptions/:id', to: 'subscriptions#show'
      post 'subscriptions', to: 'subscriptions#create'
      patch 'subscriptions/:id', to: 'subscriptions#update'
      put 'subscriptions/:id', to: 'subscriptions#update'
      delete 'subscriptions/:id', to: 'subscriptions#destroy'
    end
  end

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
end
