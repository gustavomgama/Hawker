class DriverChannel < ApplicationCable::Channel
  def subscribed
    stream_from "driver_channel" if current_user
  end

  def unsubscribed; end
end
