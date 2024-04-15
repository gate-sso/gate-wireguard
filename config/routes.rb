Rails.application.routes.draw do
  resources :configurations
  resources :vpn_devices
  get 'home/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'logout', to: 'sessions#destroy', as: 'logout'

  get 'admin/users'
  get 'admin/vpn_configurations'
  # Defines the root path route ("/")
  root "admin#index"
  get 'login', to:'home#login', as: 'login'
end
