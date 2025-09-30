class HandleDeliveryRequest < BaseCase
  attributes :request_id, :action

  def call!
    request = delivery_state.get_request(request_id)

    return Failure(result: { error: "Request not found" }) unless request

    return Failure(result: { error: "Driver not available" }) unless delivery_state.driver_working?

    case action.to_s
    when "accept"
      accept_request(request)
    when "dismiss"
      dismiss_request(request)
    else
      Failure(result: { error: "Invalid action: #{action}" })
    end
  end

  private

  def accept_request(request)
    unless request[:status] == "pending"
      return Failure(result: { error: "Request is no longer pending" })
    end

    driver_location = delivery_state.driver_location

    unless driver_location
      return Failure(result: { error: "Driver location unknown" })
    end

    updated_request = delivery_state.update_request_status(
      request_id,
      "accepted"
    )

    broadcast_to_customer(request_id, {
      type: "request_accepted",
      message: "Driver is on the way!",
      driver_location:
    })

    Success(result: {
      message: "Request accepted",
      request: updated_request
    })
  end

  def dismiss_request(request)
    delivery_state.remove_request(request_id)

    if request[:status] == "pending"
      broadcast_to_customer(request_id, {
        type: "request_dismissed",
        message: "Your request has been dismissed. Please try again later."
      })
    end

    Success(result: {
      message: "Request dismissed",
      request:
    })
  end
end
