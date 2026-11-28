class PositionsController < ApplicationController
  before_action :authenticate_hawker

  def create
    return head :conflict unless HawkerProfile.instance.broadcasting?

    Position.create!(position_params)
    head :no_content
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  private

  def position_params
    params.require(:position).permit(:latitude, :longitude)
  end
end
