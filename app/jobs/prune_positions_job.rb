class PrunePositionsJob < ApplicationJob
  def perform
    Position.delete_all
  end
end
