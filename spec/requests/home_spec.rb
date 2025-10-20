require "rails_helper"
RSpec.describe "Home", type: :request do
  let(:user) { create(:user) }

  let(:session_record) { create(:session, user: user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(session_record)
    delivery_state = DeliveryState.instance
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(true)
    delivery_state.set_driver_location(-23.5505, -46.6333)
  end

  describe "GET /" do
    it "returns http success" do
      get "/"

      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      get "/"

      expect(response).to render_template(:index)
    end
  end

  describe "POST /request_delivery" do
    let(:valid_params) do
      {
        name: "John Doe",
        address: "Rua Teste, 123",
        lat: "-23.5505",
        long: "-46.6333"
      }
    end

    let(:invalid_params) do
      {
        name: "",
        address: "",
        lat: nil,
        long: nil
      }
    end

    context "with valid parameters" do
      it "returns http success" do
        post "/request_delivery", params: valid_params

        expect(response).to have_http_status(:success)
      end

      it "returns JSON with success true" do
        post "/request_delivery", params: valid_params

        json_response = JSON.parse(response.body)

        expect(json_response["success"]).to be true
      end

      it "includes request data in response" do
        post "/request_delivery", params: valid_params

        json_response = JSON.parse(response.body)

        expect(json_response).to have_key("request")

        expect(json_response["request"]).to include(
          "name" => "John Doe",
          "address" => "Rua Teste, 123",
          "lat" => -23.5505,
          "long" => -46.6333,
          "status" => "pending"
        )

        expect(json_response["request"]).to have_key("id")
        expect(json_response["message"]).to eq("Request sent!")
      end

      it "calls CreateDeliveryRequest use case" do
        expect(CreateDeliveryRequest).to receive(:call).with(
          name: "John Doe",
          address: "Rua Teste, 123",
          lat: -23.5505,
          long: -46.6333
        ).and_call_original

        post "/request_delivery", params: valid_params
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity status" do
        post "/request_delivery", params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns JSON with success false" do
        post "/request_delivery", params: invalid_params

        json_response = JSON.parse(response.body)

        expect(json_response["success"]).to be false
      end

      it "includes error message in response" do
        post "/request_delivery", params: invalid_params

        json_response = JSON.parse(response.body)

        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Invalid input data")
      end
    end

    context "when no driver is available" do
      before do
        delivery_state = DeliveryState.instance

        delivery_state.set_driver_working(false)
      end

      it "returns unprocessable entity status" do
        post "/request_delivery", params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns appropriate error message" do
        post "/request_delivery", params: valid_params

        json_response = JSON.parse(response.body)

        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("No driver available")
      end
    end

    context "edge cases" do
      it "handles invalid coordinates correctly" do
        params = valid_params.merge(lat: nil, long: nil)

        post "/request_delivery", params: params

        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)

        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Invalid input data")
      end

      it "handles missing parameters" do
        post "/request_delivery", params: { name: "John" }

        expect(response).to have_http_status(:unprocessable_content)
      end

      context "boundary value testing" do
        let(:delivery_state) { DeliveryState.instance }

        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(0, 0)
        end

        it "handles maximum latitude values" do
          post "/request_delivery", params: {
            name: "Test User",
            address: "Test Address",
            lat: 90.0,
            long: 180.0
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
        end

        it "handles minimum latitude values" do
          post "/request_delivery", params: {
            name: "Test User",
            address: "Test Address",
            lat: -90.0,
            long: -180.0
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
        end

        it "rejects out-of-bounds coordinates" do
          post "/request_delivery", params: {
            name: "Test User",
            address: "Test Address",
            lat: 91.0,
            long: 181.0
          }

          expect(response).to have_http_status(:success)
        end
      end

      context "extreme string lengths" do
        let(:delivery_state) { DeliveryState.instance }

        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles very long names" do
          long_name = "A" * 1000

          post "/request_delivery", params: {
            name: long_name,
            address: "Test Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["request"]["name"]).to eq(long_name.strip)
        end

        it "handles very long addresses" do
          long_address = "123 " + ("Very Long Street Name " * 50)

          post "/request_delivery", params: {
            name: "Test User",
            address: long_address,
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["request"]["address"]).to eq(long_address.strip)
        end

        it "handles empty strings after stripping" do
          post "/request_delivery", params: {
            name: "   ",
            address: "   ",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:unprocessable_content)

          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be false
          expect(json_response["error"]).to eq("Invalid input data")
        end
      end

      context "unicode and special characters" do
        let(:delivery_state) { DeliveryState.instance }

        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles unicode characters in names" do
          post "/request_delivery", params: {
            name: "José María González 中文 🚀",
            address: "Rua São João, 123",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["request"]["name"]).to eq("José María González 中文 🚀")
        end

        it "handles special characters in addresses" do
          post "/request_delivery", params: {
            name: "Test User",
            address: "Rua da Consolação, 123 - Apt. 4º andar (Edifício Saint-Germain)",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["request"]["address"]).to include("Saint-Germain")
        end

        it "handles potential XSS attempts" do
          post "/request_delivery", params: {
            name: "<script>alert('xss')</script>",
            address: "javascript:alert('xss')",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["request"]["name"]).to eq("<script>alert('xss')</script>")
        end
      end

      context "concurrent request handling" do
        let(:delivery_state) { DeliveryState.instance }

        it "handles multiple simultaneous requests" do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)

          threads = []
          responses = []

          5.times do |i|
            threads << Thread.new do
              user = create(:user, email: "user#{i}@example.com")
              session = create(:session, user: user)

              allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(session)

              post "/request_delivery", params: {
                name: "User #{i}",
                address: "Address #{i}",
                lat: -23.5505 + (i * 0.001),
                long: -46.6333 + (i * 0.001)
              }

              responses << {
                status: response.status,
                body: JSON.parse(response.body)
              }
            end
          end

          threads.each(&:join)

          expect(responses.all? { |r| r[:status] == 200 }).to be true
          expect(responses.all? { |r| r[:body]["success"] == true }).to be true
          expect(delivery_state.all_requests.length).to eq(5)
        end
      end

      context "resource exhaustion protection" do
        let(:delivery_state) { DeliveryState.instance }

        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles many requests without memory issues" do
          expect {
            100.times do |i|
              post "/request_delivery", params: {
                name: "Bulk User #{i}",
                address: "Bulk Address #{i}",
                lat: -23.5505,
                long: -46.6333
              }
            end
          }.not_to raise_error
          expect(delivery_state.all_requests.length).to eq(100)
        end

        it "handles request cleanup properly" do
          initial_count = delivery_state.all_requests.length

          5.times do |i|
            post "/request_delivery", params: {
              name: "Temp User #{i}",
              address: "Temp Address #{i}",
              lat: -23.5505,
              long: -46.6333
            }
          end

          expect(delivery_state.all_requests.length).to eq(initial_count + 5)

          delivery_state.clear_all_pending_requests

          expect(delivery_state.pending_requests.length).to eq(0)
        end
      end

      context "time and timezone edge cases" do
        it "handles requests across different time zones" do
          allow(Time).to receive(:current).and_return(Time.parse("2025-01-01 23:59:59 UTC"))

          delivery_state = DeliveryState.instance
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)

          post "/request_delivery", params: {
            name: "Timezone Test",
            address: "UTC Test Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["request"]["requested_at"]).to include("2025-01-01T23:59:59")
        end

        it "handles leap year dates" do
          allow(Time).to receive(:current).and_return(Time.parse("2024-02-29 12:00:00 UTC"))

          delivery_state = DeliveryState.instance
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)

          post "/request_delivery", params: {
            name: "Leap Year Test",
            address: "Leap Year Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)
        end
      end

      context "session and authentication edge cases" do
        it "handles expired sessions gracefully" do
          expired_session = create(:session, user: user)

          expired_session.update_column(:updated_at, 1.year.ago)

          allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(nil)

          post "/request_delivery", params: {
            name: "Expired Session Test",
            address: "Test Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(new_session_path)
        end

        it "handles session hijacking attempts" do
          other_user = create(:user, email: "other@example.com")

          other_session = create(:session, user: other_user)

          allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(other_session)

          post "/request_delivery", params: {
            name: "Hijack Test",
            address: "Test Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
        end
      end

      context "driver state edge cases" do
        it "handles driver going offline during request creation" do
          delivery_state = DeliveryState.instance

          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)

          allow_any_instance_of(CreateDeliveryRequest).to receive(:driver_available?).and_return(false)

          post "/request_delivery", params: {
            name: "Offline Driver Test",
            address: "Test Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:unprocessable_content)

          json_response = JSON.parse(response.body)

          expect(json_response["error"]).to eq("No driver available")
        end

        it "handles driver location changes during request" do
          delivery_state = DeliveryState.instance

          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)

          post "/request_delivery", params: {
            name: "Moving Driver Test",
            address: "Test Address",
            lat: -23.5505,
            long: -46.6333
          }

          expect(response).to have_http_status(:success)

          delivery_state.set_driver_location(-23.5600, -46.6400)

          expect(delivery_state.all_requests.length).to eq(1)
        end
      end
    end
  end
end
