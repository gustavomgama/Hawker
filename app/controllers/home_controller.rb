class HomeController < ApplicationController
  def index
    @profile = HawkerProfile.instance
  end
end
