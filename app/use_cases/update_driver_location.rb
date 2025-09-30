class UpdateDriverLocation < BaseCase
  attributes :lat, :long

  def call!
    unless delivery_state.driver_working?
      return Failure(result: { error: "Driver is not working" })
    end

    unless valid_coordinates?
      return Failure(result: { error: "Invalid coordinates" })
    end

    delivery_state.set_driver_location(lat, long)

    pending_requests = delivery_state.pending_requests

    broadcast_to_all_customers({
      type: "driver_location_update",
      location: {
        lat:,
        long:,
        updated_at: Time.current.iso8601
      }
    })

    Success(result: {
      message: "Location updated",
      location: { lat:, long: },
      pending_requests:
    })
  end

  private

  def valid_coordinates?
    lat.present? && long.present? &&
    lat.is_a?(Numeric) && long.is_a?(Numeric)
  end
end
