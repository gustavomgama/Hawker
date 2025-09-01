Rails.application.routes.draw do
  root "home#index"

  namespace :driver do
    root "dashboard#index"
    post "update_location", to: "dashboard#update_location"
    post "set_status", to: "dashboard#set_status"
    post "complete_request/:id", to: "dashboard#complete_request", as: "complete_request"
  end

  get "driver_status", to: "home#driver_status"

  resource :session
  resources :passwords, param: :token
  resources :requests, only: [:create]

  get "up" => "rails/health#show", as: :rails_health_check
end
