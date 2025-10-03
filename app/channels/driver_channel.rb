class DriverChannel < ApplicationCable::Channel
  def subscribed
    current_user ? stream_from("driver_channel") : reject
  end

  def unsubscribed
    stop_all_streams
  end
end
