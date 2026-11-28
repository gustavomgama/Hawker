class HawkerProfile < ApplicationRecord
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
end
