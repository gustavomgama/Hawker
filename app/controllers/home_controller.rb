class HomeController < ApplicationController
  def index; end

  def request_delivery
    result = CreateDeliveryRequest.call(
      name: params[:name],
      address: params[:address],
      lat: params[:lat]&.to_f,
      long: params[:long]&.to_f
    )

    if result.success?
      render json: { success: true }.merge(result.value[:result])
    else
      render json: { success: false }.merge(result.value[:result]), status: :unprocessable_entity
    end
  end
end
