require "test_helper"

class StopsControllerTest < ActionDispatch::IntegrationTest
  test "a request becomes a requested stop and returns to the customer screen" do
    profile.go_online!

    assert_difference -> { Stop.requested.count }, 1 do
      post stops_path, params: { stop: { customer_name: "Ana", address: "Rua A 10", items: "2 empanadas" } }
    end

    assert_redirected_to root_path

    stop = Stop.requested.last
    assert_equal "Rua A 10", stop.address
    assert_equal "2 empanadas", stop.items
    assert_equal "Ana", stop.customer.name

    follow_redirect!
    assert_select "form.ask"
    assert_select "p.notice", "Your request is with the hawker."
  end

  test "the request form is absent while the hawker is not working" do
    get "/"

    assert_select "form.ask", count: 0
  end

  test "a request sent after the hawker stopped is refused and records nothing" do
    assert_no_difference [ -> { Stop.count }, -> { Customer.count } ] do
      post stops_path, params: { stop: { customer_name: "Ana", address: "Rua A 10" } }
    end

    assert_redirected_to root_path

    follow_redirect!
    assert_select "p.alert", "Your hawker is not working, so nothing was sent."
  end

  test "accepting a request puts it on the route and removes its row without a reload" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")

    patch stop_path(stop), params: { state: "accepted" }, as: :turbo_stream

    assert_response :success
    assert_equal "accepted", stop.reload.status
    assert_equal 1, stop.sequence
    assert_includes response.body, 'action="replace"'
    assert_includes response.body, 'target="workspace"'
    assert_includes response.body, "0 waiting · 1 on the route"
  end

  test "declining a request takes it out of the queue without a reload" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")

    patch stop_path(stop), params: { state: "declined" }, as: :turbo_stream

    assert_response :success
    assert_equal "declined", stop.reload.status
    assert_equal 0, Stop.requested.count
    assert_includes response.body, "0 waiting · 0 on the route"
    assert_not_includes response.body, "Rua A 10"
  end

  test "a second answer is refused and leaves the stop where it is" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")
    stop.accept!

    patch stop_path(stop), params: { state: "declined" }, as: :turbo_stream

    assert_response :conflict
    assert_equal "accepted", stop.reload.status
  end

  test "a stop answered without streams falls back to the hawker screen" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")

    patch stop_path(stop), params: { state: "accepted" }

    assert_redirected_to hawker_path
    assert_equal "accepted", stop.reload.status
  end

  test "arriving keeps the stop on the route" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")
    stop.accept!

    patch stop_path(stop), params: { state: "arrived" }, as: :turbo_stream

    assert_response :success
    assert_equal "arrived", stop.reload.status
    assert_not_nil stop.arrived_at
    assert_includes response.body, "1 on the route"
    assert_includes response.body, "Rua A 10"
  end

  test "fulfilling takes an arrived stop off the route" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")
    stop.accept!
    stop.arrive!

    patch stop_path(stop), params: { state: "fulfilled" }, as: :turbo_stream

    assert_response :success
    assert_equal "fulfilled", stop.reload.status
    assert_includes response.body, "0 on the route"
    assert_not_includes response.body, "Rua A 10"
  end

  test "a stop cannot be fulfilled before it is arrived" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")
    stop.accept!

    patch stop_path(stop), params: { state: "fulfilled" }, as: :turbo_stream

    assert_response :conflict
    assert_equal "accepted", stop.reload.status
  end

  test "an unknown answer changes nothing" do
    profile.go_online!
    stop = Stop.request!(customer_name: "Ana", address: "Rua A 10")

    patch stop_path(stop), params: { state: "cooked" }

    assert_response :bad_request
    assert_equal "requested", stop.reload.status
  end
end
