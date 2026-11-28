class StopsController < ApplicationController
  before_action :authenticate_hawker, only: :update

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
    when "arrived" then stop.arrive!
    when "fulfilled" then stop.fulfill!
    else return head :bad_request
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "workspace",
          partial: "hawkers/workspace",
          locals: { requests: Stop.requested.order(:created_at), route: Stop.on_route }
        )
      end
      format.html { redirect_to hawker_path }
    end
  rescue Stop::InvalidTransition
    head :conflict
  end
end
