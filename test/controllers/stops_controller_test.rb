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
end
