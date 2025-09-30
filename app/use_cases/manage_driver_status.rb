class ManageDriverStatus < BaseCase
  attributes :action, :lat, :long

  def call!
    case action.to_s
    when "start_working"
      start_working
    when "stop_working"
      stop_working
    else
      Failure(result: { error: "Invalid action: #{action}" })
    end
  end

  private

  def start_working
    unless valid_location?
      return Failure(result: { error: "Valid location required to start working " })
    end

    delivery_state.set_driver_working(true)
    delivery_state.set_driver_location(lat, long)

    broadcast_to_all_customers({
      type: "driver_online",
      location: {
        lat:,
        long:,
        updated_at: Time.current.iso8601
      }
    })

    Success(result: {
      message: "You're now working!",
      working: true,
      location: { lat:, long: }
    })
  end

  def stop_working
    cleared_request_ids = delivery_state.clear_all_pending_requests

    delivery_state.set_driver_working(false)

    cleared_request_ids.each do |request_id|
      broadcast_to_customer(request_id, {
        type: "request_dismissed",
        message: "Driver is no longer available. Please try again later."
      })
    end

    broadcast_to_all_customers({
      type: "driver_offline",
      message: "Driver is no longer available"
    })

    Success(result: {
      message: "You're now offline",
      working: false,
      dismissed_requests: cleared_request_ids.count
    })
  end

  def valid_location?
    lat.present? && long.present? &&
    lat.is_a?(Numeric) && long.is_a?(Numeric)
  end
end
