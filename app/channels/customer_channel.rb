class CustomerChannel < ApplicationCable::Channel
  def subscribed
    request_id = params[:request_id]

    if request_exists?(request_id)
      stream_from "customer_#{request_id}"
    else
      reject
    end
  end

  def unsubscribed; end

  private

  def request_exists?(request_id)
    DeliveryState.instance.get_request(request_id).present?
  end
end
