Rails.application.routes.draw do
  resources :configurations
  resources :vpn_devices
  get 'dns_records/refresh', to: 'dns_records#refresh_zones', as: 'refresh_dns_records'
  resources :dns_records
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
  patch 'admin/vpn_configuration/:id', to: 'admin#update_vpn_configuration', as: 'update_vpn_configuration'

  post 'admin/:id/network_address', to: 'admin#add_network_address', as: 'add_network_address'
  delete 'admin/network_address/:id', to: 'admin#remove_network_address', as: "remove_network_address"

  # download the wireguard configuration file
  get 'vpn_devices/download/:id', to: 'vpn_devices#download_config', as: 'download_config'

  # Defines the root path route ("/")
  root "admin#index"
  get 'login', to:'home#login', as: 'login'


end
