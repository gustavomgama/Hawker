require "test_helper"

class StopTest < ActiveSupport::TestCase
  test "cannot request a stop while the hawker is offline" do
    assert_raises(Stop::Unavailable) do
      Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")
    end

    assert_equal 0, Stop.count
  end

  test "accepting appends a stop to the route order" do
    profile.go_online!

    first = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")
    second = Stop.request!(customer_name: "Bia", address: "Rua B 20", items: "2")

    assert_equal "requested", first.status
    assert_nil first.sequence

    first.accept!
    second.accept!

    assert_equal 1, first.reload.sequence
    assert_equal 2, second.reload.sequence
  end

  test "accepting moves a requested stop to accepted" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")

    stop.accept!

    assert_equal "accepted", stop.status
    assert_not_nil stop.accepted_at
  end

  test "a stop cannot be accepted twice" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")
    stop.accept!

    assert_raises(Stop::InvalidTransition) { stop.accept! }
  end

  test "declining a requested stop ends it" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")

    stop.decline!

    assert_equal "declined", stop.status
  end

  test "arriving and fulfilling complete the stop" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")
    stop.accept!
    stop.arrive!
    stop.fulfill!

    assert_equal "fulfilled", stop.status
    assert_not_nil stop.arrived_at
  end

  test "a customer is reused by phone" do
    profile.go_online!

    Stop.request!(customer_name: "Ana", customer_phone: "11999", address: "Rua A 10", items: "1")
    Stop.request!(customer_name: "Ana", customer_phone: "11999", address: "Rua B 20", items: "2")

    assert_equal 1, Customer.count
    assert_equal 2, Customer.first.stops.count
  end
end
