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
end
