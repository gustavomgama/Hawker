class Driver::DashboardController < Driver::BaseController
  def index
    result = GetDriverDashboard.call

    if result.success?
      dashboard_data = result.value[:result]
      @working = dashboard_data[:working]
      @pending_requests = dashboard_data[:pending_requests]
      @accepted_requests = dashboard_data[:accepted_requests]
      @driver_location = dashboard_data[:location]
    else
      @working = false
      @pending_requests = []
      @accepted_requests = []
      @driver_location = nil
    end
  end

  def handle_working_status
    result = ManageDriverStatus.call(
      action: params[:action_type],
      lat: params[:lat]&.to_f,
      long: params[:long]&.to_f
    )

    if result.success?
      render json: { success: true }.merge(result.value[:result])
    else
      render json: { success: false }.merge(result.value[:result]), status: :bad_request
    end
  end

  def handle_request
    result = HandleDeliveryRequest.call(
      request_id: params[:id],
      action: params[:action_type]
    )

    if result.success?
      render json: { success: true }.merge(result.value[:result])
    else
      render json: { success: false }.merge(result.value[:result]), status: :bad_request
    end
  end

  def update_location
    result = UpdateDriverLocation.call(
      lat: params[:lat]&.to_f,
      long: params[:long]&.to_f
    )

    if result.success?
      render json: { success: true }.merge(result.value[:result])
    else
      render json: { success: false }.merge(result.value[:result]), status: :bad_request
    end
  end
end
