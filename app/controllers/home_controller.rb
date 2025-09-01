class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @driver_state = DriverState.instance.driver_state
  end

  def driver_status
    render json: DriverState.instance.driver_state
  end
end
