require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  test "a position sent while broadcasting is recorded" do
    profile.go_online!

    assert_difference -> { Position.count }, 1 do
      post positions_path, params: { position: { latitude: -23.550520, longitude: -46.633308 } }, headers: hawker_auth
    end

    assert_response :no_content
    position = Position.last
    assert_equal(-23.55052, position.latitude.to_f)
    assert_equal(-46.633308, position.longitude.to_f)
  end

  test "a position needs the hawker credentials" do
    profile.go_online!

    assert_no_difference -> { Position.count } do
      post positions_path, params: { position: { latitude: 1, longitude: 2 } }
    end

    assert_response :unauthorized
  end

  test "a position sent while paused is refused" do
    profile.go_online!
    profile.pause!

    assert_no_difference -> { Position.count } do
      post positions_path, params: { position: { latitude: 1, longitude: 2 } }, headers: hawker_auth
    end

    assert_response 409
  end

  test "an impossible coordinate is refused" do
    profile.go_online!

    assert_no_difference -> { Position.count } do
      post positions_path, params: { position: { latitude: 200, longitude: 2 } }, headers: hawker_auth
    end

    assert_response 422
  end
end
