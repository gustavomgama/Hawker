class CustomerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "customer_updates"

    if params[:request_id].present?
      stream_from "customer_#{params[:request_id]}"
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
