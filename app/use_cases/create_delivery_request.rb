class CreateDeliveryRequest < BaseCase
  attributes :name, :address, :lat, :long

  def call!
    unless validate_inputs
      return Failure(result: { error: "Invalid input data" })
    end

    unless driver_available?
      return Failure(result: { error: "No driver available" })
    end

    request_data = build_request_data

    delivery_state.add_request(request_data[:id], request_data)

    broadcast_to_driver({
      type: "new_request",
      request: request_data
    })

    Success(result: {
      message: "Request sent!",
      request: request_data
    })
  end

  private

  def validate_inputs
    name.present? &&
    address.present? &&
    lat.present? && lat.is_a?(Numeric) &&
    long.present? && long.is_a?(Numeric)
  end

  def driver_available?
    delivery_state.driver_working?
  end

  def build_request_data
    {
      id: SecureRandom.uuid,
      name: name.strip,
      address: address.strip,
      lat: lat.to_f,
      long: long.to_f,
      requested_at: Time.current,
      status: "pending"
    }
  end
end
