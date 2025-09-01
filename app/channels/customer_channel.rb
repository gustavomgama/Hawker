# app/channels/customer_channel.rb
class CustomerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "customer_updates"

    # Send current driver state on connect
    transmit({
      action: "driver_update",
      driver_state: BakeryState.instance.driver_state
    })
  end
end
