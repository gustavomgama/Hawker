Rails.application.routes.draw do
  root "home#index"

  resource :session
  resources :passwords, param: :token

  namespace :driver do
    get "dashboard/index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
