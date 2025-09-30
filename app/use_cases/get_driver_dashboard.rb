class GetDriverDashboard < BaseCase
  def call!
    dashboard_data = {
      working: delivery_state.driver_working?,
      location: delivery_state.driver_location,
      pending_requests: delivery_state.pending_requests.sort_by { |req| req[:requested_at] },
      accepted_requests:
    }

    Success(result: dashboard_data)
  end

  private

  def accepted_requests
    delivery_state.all_requests
      .select { |req| req[:status] == "accepted" }
      .sort_by { |req| req[:accepted_at] || req[:requested_at] }
  end
end
