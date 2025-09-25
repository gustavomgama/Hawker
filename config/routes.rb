Rails.application.routes.draw do
  get "home/index"
  root "home#index"

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
end
