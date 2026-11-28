require "test_helper"
require "turbo/broadcastable/test_helper"

class HawkerProfileTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActiveJob::TestHelper

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

  test "going online broadcasts the customer stall" do
    stream = capture_turbo_stream_broadcasts("hawker_profile") { profile.go_online! }

    assert_equal 1, stream.size
    assert_equal "replace", stream.first["action"]
    assert_equal "stall", stream.first["target"]
  end

  test "going offline broadcasts the customer stall" do
    profile.go_online!

    assert_turbo_stream_broadcasts "hawker_profile" do
      profile.go_offline!
    end
  end

  test "going offline discards every recorded position" do
    profile.go_online!
    Position.create!(latitude: 1, longitude: 2)

    assert_enqueued_jobs 1, only: PrunePositionsJob do
      profile.go_offline!
    end
    perform_enqueued_jobs

    assert_empty Position.all
  end

  test "pausing does not broadcast the stall" do
    profile.go_online!

    assert_empty capture_turbo_stream_broadcasts("hawker_profile") { profile.pause! }
  end
end
