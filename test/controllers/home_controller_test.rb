require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "says the hawker is working while online" do
    profile.go_online!

    get "/"

    assert_response :success
    assert_select "h1", "Your hawker is working"
  end

  test "subscribes to the stall stream" do
    get "/"

    assert_select "turbo-cable-stream-source"
  end

  test "says the hawker is not working while offline" do
    get "/"

    assert_response :success
    assert_select "h1", "Your hawker is not working"
  end

  test "shows when the position was last recorded" do
    profile.go_online!
    Position.create!(latitude: 1, longitude: 2, created_at: Time.utc(2026, 11, 28, 14, 3))

    get "/"

    assert_select "p.last-seen", "Last seen at 14:03"
  end

  test "shows the last recorded position while paused" do
    profile.go_online!
    Position.create!(latitude: 1, longitude: 2, created_at: Time.utc(2026, 11, 28, 14, 3))
    profile.pause!

    get "/"

    assert_select "p.last-seen", "Last seen at 14:03"
  end

  test "says nothing about position while offline" do
    Position.create!(latitude: 1, longitude: 2)

    get "/"

    assert_select "p.last-seen", count: 0
  end
end
