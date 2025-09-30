class CustomerUpdatesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "customer_updates"
  end

  def unsubscribed; end
end
