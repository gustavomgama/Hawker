class BaseController < ApplicationController
  allow_unauthenticated_access
  before_action :ensure_driver

  private

  def ensure_driver
    redirect_to root_path unless current_user.driver?
  end
end
