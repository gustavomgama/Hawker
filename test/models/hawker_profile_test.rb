require "test_helper"

class HawkerProfileTest < ActiveSupport::TestCase
  test "starts offline and not broadcasting" do
    assert_not profile.working?
    assert_not profile.broadcasting?
  end

  test "going online starts broadcasting" do
    profile.go_online!

    assert profile.working?
    assert profile.broadcasting?
  end

  test "going offline voids requested stops" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "2 empanadas")

    profile.go_offline!

    assert_equal "voided", stop.reload.status
  end

  test "going offline drops accepted stops" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "2 empanadas")
    stop.accept!

    profile.go_offline!

    assert_equal "dropped", stop.reload.status
  end

  test "going offline clears the route order" do
    profile.go_online!
    first = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")
    second = Stop.request!(customer_name: "Bia", address: "Rua B 20", items: "2")
    first.accept!
    second.accept!

    profile.go_offline!

    assert_nil first.reload.sequence
    assert_nil second.reload.sequence
  end

  test "pausing keeps accepted stops on the route" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "1")
    stop.accept!

    profile.pause!

    assert_not profile.broadcasting?
    assert profile.working?
    assert_equal "accepted", stop.reload.status
  end
end
