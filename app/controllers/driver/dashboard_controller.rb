# app/controllers/driver/dashboard_controller.rb
class Driver::DashboardController < ApplicationController
  def index
    @requests = DriverState.instance.pending_requests
    @driver_state = DriverState.instance.driver_state
  end

  def update_location
    location = params[:location]

    if location.present?
      DriverState.instance.update_driver_location(location)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("driver_status", partial: "driver/status_panel",
                               locals: { driver_state: DriverState.instance.driver_state }),
            turbo_stream.replace("requests_list", partial: "driver/requests_list",
                               locals: { requests: DriverState.instance.pending_requests })
          ]
        end
        format.html { redirect_to driver_root_path, notice: "Status atualizado!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("driver_status",
            partial: "driver/status_panel_error",
            locals: {
              driver_state: DriverState.instance.driver_state,
              error: "Localização é obrigatória"
            })
        end
        format.html { redirect_to driver_root_path, alert: "Localização é obrigatória" }
      end
    end
  end

  def set_status
    status = params[:status]

    if status == "offline"
      DriverState.instance.set_driver_offline
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "driver_status",
          partial: "driver/status_panel",
          locals: { driver_state: DriverState.instance.driver_state }
        )
      end
      format.html { redirect_to driver_root_path, notice: "Status atualizado!" }
    end
  end

  def complete_request
    DriverState.instance.complete_request(params[:id])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "requests_list",
          partial: "driver/requests_list",
          locals: { requests: DriverState.instance.pending_requests }
        )
      end
      format.html { redirect_to driver_root_path, notice: "Pedido concluído!" }
    end
  end
end
