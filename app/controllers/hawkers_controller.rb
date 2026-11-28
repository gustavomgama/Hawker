class HawkersController < ApplicationController
  def show
    @profile = HawkerProfile.instance
    @requests = Stop.requested.order(:created_at)
  end

  def update
    profile = HawkerProfile.instance

    case params[:state]
    when "working" then profile.go_online!
    when "stopped" then profile.go_offline!
    when "paused" then profile.pause!
    when "broadcasting" then profile.resume!
    else return head :bad_request
    end

    redirect_to hawker_path
  end
end
