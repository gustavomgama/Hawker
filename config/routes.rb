Rails.application.routes.draw do
  mount ActionCable.server => "/cable"
  root "home#index"
  post "request_delivery", to: "home#request_delivery"

  resource :session
  resources :passwords, param: :token

  namespace :driver do
    root "dashboard#index"
    post "manage_working_status", to: "dashboard#handle_working_status"
    post "handle_request/:id", to: "dashboard#handle_request", as: :handle_request
    patch "update_location", to: "dashboard#update_location"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
