class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def authenticate_hawker
    http_basic_authenticate_or_request_with(
      name: ENV.fetch("HAWKER_USERNAME"),
      password: ENV.fetch("HAWKER_PASSWORD"),
      realm: "Hawker"
    )
  end
end
