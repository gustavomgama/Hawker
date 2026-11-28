class HawkerProfile < ApplicationRecord
  after_update_commit :broadcast_stall, if: -> { saved_change_to_availability? }

  def self.instance
    find_or_create_by!(id: 1)
  end

  def working?
    availability == "online"
  end

  def go_online!
    update!(availability: "online", broadcasting: true)
  end

  def go_offline!
    transaction do
      Stop.requested.find_each(&:void!)
      Stop.on_route.find_each(&:drop!)
      update!(availability: "offline", broadcasting: false)
    end
  end

  def pause!
    update!(broadcasting: false)
  end

  def resume!
    update!(broadcasting: true) if working?
  end

  private

  def broadcast_stall
    broadcast_replace_to "hawker_profile", target: "stall", partial: "home/stall", locals: { profile: self }
  end
end
