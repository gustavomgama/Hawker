class BaseCase < Micro::Case
  include TurboBroadcastHelper

  private

  def delivery_state
    @delivery_state ||= DeliveryState.instance
  end

  # TODO: Distance/routing calculations will be handled by the map library

  # LEGACY: ??
  def broadcast_to_driver(data)
    ActionCable.server.broadcast("driver_channel", data)
  end

  def broadcast_to_customer(request_id, data)
    ActionCable.server.broadcast("customer_#{request_id}", data)
  end

  def broadcast_to_all_customers(data)
    ActionCable.server.broadcast("customer_updates", data)
  end
end
