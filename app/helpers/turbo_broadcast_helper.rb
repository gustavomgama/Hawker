module TurboBroadcastHelper
  def broadcast_new_request_to_driver(request)
    Turbo::StreamsChannel.broadcast_append_to(
      "driver_channel",
      target: "pending_requests",
      partial: "driver/dashboard/request_card",
      locals: { request: }
    )
  end

  def broadcast_remove_request_from_driver(request_id)
    Turbo::StreamsChannel.broadcast_remove_to(
      "driver_channel",
      target: "request_#{request_id}"
    )
  end

  def broadcast_driver_status_to_customers(status, location = nil)
    Turbo::StreamsChannel.broadcast_replace_to(
      "customer_updates",
      target: "driver_status",
      partial: "home/driver_status",
      locals: { working: status, location: }
    )
  end

  def broadcast_request_accepted_to_customer(request_id, driver_location)
    Turbo::StreamsChannel.broadcast_replace_to(
      "customer_#{request_id}",
      target: "request_status",
      partial: "home/request_accepted",
      locals: { driver_location: }
    )
  end

  def broadcast_request_dismissed_to_customer(request_id)
    Turbo::StreamsChannel.broadcast_replace_to(
      "customer_#{request_id}",
      target: "request_status",
      partial: "home/request_dismissed"
    )
  end
end
