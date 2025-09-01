class DriverState
  include Singleton

  def initialize
    @driver_state = {
      status: "offline",
      location: nil,
      last_seen: nil
    }

    @request_queue = []
    @mutex = Mutex.new
  end

def update_driver_location(location)
    Rails.logger.info "BakeryState: Updating driver location to: #{location}"

    @mutex.synchronize do
      @driver_state[:location] = location
      @driver_state[:status] = "online"
      @driver_state[:last_seen] = Time.current
      reorganize_queue
    end
    broadcast_driver_update

    Rails.logger.info "BakeryState: Driver state updated: #{@driver_state}"
  end

  def set_driver_offline
    @mutex.synchronize do
      @driver_state[:status] = "offline"
      @driver_state[:location] = nil
    end
    broadcast_driver_update
  end

  def driver_state
    @driver_state.dup
  end

  def driver_online?
    @driver_state[:status] == "online"
  end

  def add_request(customer_name, location)
    request = {
      id: SecureRandom.uuid,
      customer_name:,
      location:,
      timestamp: Time.current,
      status: "pending"
    }

    @mutex.synchronize do
      @request_queue << request
      reorganize_queue
    end

    broadcast_new_request
    request[:id]
  end

  def complete_request(request_id)
    @mutex.synchronize do
      @request_queue.reject! { |request| request[:id] == request_id }
    end
    broadcast_queue_update
  end

  def pending_requests
    @request_queue.dup
  end

  private

  def reorganize_queue
    return unless @driver_state[:location]

    @request_queue.sort_by! do |request|
      calculate_distance(@driver_state[:location], request[:location])
    end
  end

  def calculate_distance(location1, location2)
    return rand(1..10) if location1.nil? || location2.nil?

    addr1_parts = location1.downcase.split(/[,-]/).map(&:strip)
    addr2_parts = location2.downcase.split(/[,-]/).map(&:strip)

    same_neighborhood = addr1_parts.last == addr2_parts.last ? 1 : 5

    street_sim = addr1_parts.first.include?(addr2_parts.first[0..3]) ? 0 : 2

    same_neighborhood + street_sim + rand(1..3)
  end

  def broadcast_driver_update
    ActionCable.server.broadcast(
      "customer_updates",
      {
        action: "driver_update",
        driver_state: driver_state
      }
    )
  end

  def broadcast_new_request
    ActionCable.server.broadcast(
      "driver_updates",
      {
        action: "queue_update",
        requests: pending_requests
      }
    )
  end

  def broadcast_queue_update
    broadcast_new_request
  end
end
