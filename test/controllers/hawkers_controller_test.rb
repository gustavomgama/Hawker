require "test_helper"

class HawkersControllerTest < ActionDispatch::IntegrationTest
  test "the screen offers to start working while idle" do
    get hawker_path

    assert_response :success
    assert_select "h1", "You are not working"
    assert_select "input[name=?][value=?]", "state", "working"
    assert_select "input[name=?][value=?]", "state", "stopped", count: 0
    assert_select "input[name=?][value=?]", "state", "paused", count: 0
  end

  test "the screen offers to stop working and to pause while working" do
    profile.go_online!

    get hawker_path

    assert_select "h1", "You are working"
    assert_select "input[name=?][value=?]", "state", "stopped"
    assert_select "input[name=?][value=?]", "state", "paused"
  end

  test "going online from the screen starts working and broadcasting" do
    patch hawker_path, params: { state: "working" }

    assert_redirected_to hawker_path
    assert profile.working?
    assert profile.broadcasting?
  end

  test "stopping work voids the requests waiting for the hawker" do
    profile.go_online!
    Stop.request!(customer_name: "Ana", address: "Rua A 10")

    patch hawker_path, params: { state: "stopped" }

    assert_not profile.working?
    assert_empty Stop.requested
  end

  test "pausing stops broadcasting without ending the working day" do
    profile.go_online!

    patch hawker_path, params: { state: "paused" }

    assert profile.working?
    assert_not profile.broadcasting?

    patch hawker_path, params: { state: "broadcasting" }

    assert profile.broadcasting?
  end

  test "an unknown state changes nothing" do
    profile.go_online!

    patch hawker_path, params: { state: "closed" }

    assert_response :bad_request
    assert profile.working?
    assert profile.broadcasting?
  end
end
