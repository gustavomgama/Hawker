# app/channels/driver_channel.rb
class DriverChannel < ApplicationCable::Channel
  def subscribed
    stream_from "driver_updates"
  end

  def unsubscribed
    # Optional: Set driver offline when disconnected
  end
end
