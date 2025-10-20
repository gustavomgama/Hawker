class DeliveryState
  include Singleton

  def initialize
    @requests = Concurrent::Hash.new

    @driver = Concurrent::Hash.new
    @driver[:status] = false
    @driver[:location] = nil
    @driver[:updated_at] = nil
  end

  def all_requests
    @requests.values
  end

  def get_request(id)
    @requests[id]
  end

  def add_request(id, data)
    @requests[id] = data
  end

  def update_request_status(id, status)
    return nil unless @requests.key?(id)

    @requests[id] = @requests[id].merge(
      status:
    )
  end

  def remove_request(id)
    @requests.delete(id)
  end

  def pending_requests
    @requests.values
      .select { |req| req[:status] == "pending" }
  end

  def set_driver_working(status)
    @driver[:status] = status
    @driver[:updated_at] = Time.current
  end

  def driver_working?
    @driver[:status]
  end

  def set_driver_location(lat, long)
    @driver[:location] = {
      lat:,
      long:,
      updated_at: Time.current
    }
  end

  def driver_location
    @driver[:location]
  end

  def clear_all_pending_requests
    pending_request = @requests
      .select { |_, req| req[:status] == "pending" }
      .keys
      .each { |id| @requests.delete(id) }

    pending_request
  end
end
