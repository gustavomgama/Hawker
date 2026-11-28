class StopsController < ApplicationController
  def create
    attributes = params.require(:stop).permit(:customer_name, :address, :items)

    Stop.request!(
      customer_name: attributes[:customer_name],
      address: attributes[:address],
      items: attributes[:items].presence
    )

    redirect_to root_path, notice: "Your request is with the hawker."
  rescue Stop::Unavailable
    redirect_to root_path, alert: "Your hawker is not working, so nothing was sent."
  end

  def update
    stop = Stop.find(params[:id])

    case params[:state]
    when "accepted" then stop.accept!
    when "declined" then stop.decline!
    else return head :bad_request
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(stop) }
      format.html { redirect_to hawker_path }
    end
  rescue Stop::InvalidTransition
    head :conflict
  end
end
