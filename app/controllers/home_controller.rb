class HomeController < ApplicationController
  def index
    @profile = HawkerProfile.instance
    @last_position = @profile.last_position
  end
end
