class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    session = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]

    @current_user = session.user
  end

  helper_method :current_user
end
