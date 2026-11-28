require "test_helper"

class HawkersControllerTest < ActionDispatch::IntegrationTest
  test "the screen offers to start working while idle" do
    get hawker_path, headers: hawker_auth

    assert_response :success
    assert_select "h1", "You are not working"
    assert_select "input[name=?][value=?]", "state", "working"
    assert_select "input[name=?][value=?]", "state", "stopped", count: 0
    assert_select "input[name=?][value=?]", "state", "paused", count: 0
  end

  test "the screen offers to stop working and to pause while working" do
    profile.go_online!

    get hawker_path, headers: hawker_auth

    assert_select "h1", "You are working"
    assert_select "input[name=?][value=?]", "state", "stopped"
    assert_select "input[name=?][value=?]", "state", "paused"
  end

  test "going online from the screen starts working and broadcasting" do
    patch hawker_path, params: { state: "working" }, headers: hawker_auth

    assert_redirected_to hawker_path
    assert profile.working?
    assert profile.broadcasting?
  end

  test "stopping work voids the requests waiting for the hawker" do
    profile.go_online!
    Stop.request!(customer_name: "Ana", address: "Rua A 10")

    patch hawker_path, params: { state: "stopped" }, headers: hawker_auth

    assert_not profile.working?
    assert_empty Stop.requested
  end

  test "pausing stops broadcasting without ending the working day" do
    profile.go_online!

    patch hawker_path, params: { state: "paused" }, headers: hawker_auth

    assert profile.working?
    assert_not profile.broadcasting?

    patch hawker_path, params: { state: "broadcasting" }, headers: hawker_auth

    assert profile.broadcasting?
  end

  test "the screen lists the requests waiting for an answer and nothing else" do
    profile.go_online!
    waiting = Stop.request!(customer_name: "Ana", address: "Rua A 10", items: "2 empanadas")
    taken = Stop.request!(customer_name: "Bo", address: "Rua B 20")
    taken.accept!

    get hawker_path, headers: hawker_auth

    assert_select "#stop_#{waiting.id}" do
      assert_select "p", /Ana/
      assert_select "p", /Rua A 10/
      assert_select "input[name=?][value=?]", "state", "accepted"
      assert_select "input[name=?][value=?]", "state", "declined"
    end
    assert_select "#stop_#{taken.id}", count: 0
  end

  test "nothing is waiting to be answered while the hawker is not working" do
    get hawker_path, headers: hawker_auth

    assert_select "ul.requests", count: 0
  end

  test "the screen lists the route in sequence order with the counts" do
    profile.go_online!
    early = Stop.request!(customer_name: "Ana", address: "Rua A 10")
    late = Stop.request!(customer_name: "Bo", address: "Rua B 20")
    late.accept!
    early.accept!
    Stop.request!(customer_name: "Caio", address: "Rua C 30")

    get hawker_path, headers: hawker_auth

    assert_select "#workspace p.counts", "1 waiting · 2 on the route"
    assert_select "#workspace ol.route li", count: 2
    assert_select "#workspace ol.route li:nth-child(1)", /Rua B 20/
    assert_select "#workspace ol.route li:nth-child(2)", /Rua A 10/
  end

  test "everything starts empty on the route" do
    profile.go_online!

    get hawker_path, headers: hawker_auth

    assert_select "#workspace p.counts", "0 waiting · 0 on the route"
    assert_select "#workspace ol.route", count: 0
  end

  test "an accepted stop offers arrival and an arrived stop offers fulfilment" do
    profile.go_online!
    accepted = Stop.request!(customer_name: "Ana", address: "Rua A 10")
    accepted.accept!
    arrived = Stop.request!(customer_name: "Bo", address: "Rua B 20")
    arrived.accept!
    arrived.arrive!

    get hawker_path, headers: hawker_auth

    assert_select "#route_stop_#{accepted.id}" do
      assert_select "input[name=?][value=?]", "state", "arrived"
      assert_select "input[name=?][value=?]", "state", "fulfilled", count: 0
    end
    assert_select "#route_stop_#{arrived.id}" do
      assert_select "input[name=?][value=?]", "state", "fulfilled"
      assert_select "input[name=?][value=?]", "state", "arrived", count: 0
    end
  end

  test "an unknown state changes nothing" do
    profile.go_online!

    patch hawker_path, params: { state: "closed" }, headers: hawker_auth

    assert_response :bad_request
    assert profile.working?
    assert profile.broadcasting?
  end

  test "the desk asks for credentials" do
    get hawker_path

    assert_response :unauthorized
    assert_match(/Basic/, response.headers["WWW-Authenticate"])
  end

  test "wrong credentials do not reach the desk" do
    get hawker_path, headers: hawker_auth(password: "guess")

    assert_response :unauthorized
  end

  test "the deciding state cannot be changed without credentials" do
    patch hawker_path, params: { state: "working" }

    assert_response :unauthorized
    assert_not profile.working?
  end

  test "the right credentials reach the desk and can use it" do
    get hawker_path, headers: hawker_auth

    assert_response :success
    assert_select "h1", "You are not working"

    patch hawker_path, params: { state: "working" }, headers: hawker_auth

    assert_redirected_to hawker_path
    assert profile.working?
  end
end
