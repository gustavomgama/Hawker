class StopsController < ApplicationController
  def create
    attributes = params.require(:stop).permit(:customer_name, :address, :items)

    Stop.request!(
      customer_name: attributes[:customer_name],
      address: attributes[:address],
      items: attributes[:items].presence
    )

    redirect_to root_path, notice: "Your request is with the hawker."
  end
end
