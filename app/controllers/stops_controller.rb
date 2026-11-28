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
end
