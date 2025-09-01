class RequestsController < ApplicationController
  def create
    request_id = DriverState.instance.add_request(
      params[:customer_name],
      params[:location]
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "request_form",
          partial: "shared/request_success",
          locals: { message: "Pedido enviado! ID: #{request_id[0..7]}" }
        )
      end
      format.html { redirect_to root_path, notice: "Pedido enviado!" }
    end
  end
end
