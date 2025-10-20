require "rails_helper"

RSpec.describe "Driver::Dashboard", type: :request do
  let(:user) { create(:user) }

  let(:session_record) { create(:session, user: user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(session_record)

    delivery_state = DeliveryState.instance
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(false)
  end

  describe "GET /driver" do
    it "returns http success" do
      get "/driver"
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      get "/driver"
      expect(response).to render_template("driver/dashboard/index")
    end

    it "calls GetDriverDashboard use case" do
      expect(GetDriverDashboard).to receive(:call).and_call_original
      get "/driver"
    end
  end

  describe "POST /driver/manage_working_status" do
    let(:valid_start_params) do
      {
        action_type: "start_working",
        lat: "-23.5505",
        long: "-46.6333"
      }
    end

    let(:valid_stop_params) do
      {
        action_type: "stop_working"
      }
    end

    let(:invalid_params) do
      {
        action_type: "start_working",
        lat: nil,
        long: nil
      }
    end

    context "with valid start working parameters" do
      it "returns http success" do
        post "/driver/manage_working_status", params: valid_start_params

        expect(response).to have_http_status(:success)
      end

      it "returns JSON with success true" do
        post "/driver/manage_working_status", params: valid_start_params

        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
      end

      it "calls ManageDriverStatus use case" do
        expect(ManageDriverStatus).to receive(:call).with(
          action: "start_working",
          lat: -23.5505,
          long: -46.6333
        ).and_call_original

        post "/driver/manage_working_status", params: valid_start_params
      end
    end

    context "with valid stop working parameters" do
      it "returns http success" do
        post "/driver/manage_working_status", params: valid_stop_params

        expect(response).to have_http_status(:success)
      end

      it "calls ManageDriverStatus use case without coordinates" do
        expect(ManageDriverStatus).to receive(:call).with(
          action: "stop_working",
          lat: nil,
          long: nil
        ).and_call_original

        post "/driver/manage_working_status", params: valid_stop_params
      end
    end

    context "with invalid parameters" do
      it "returns bad request status" do
        post "/driver/manage_working_status", params: invalid_params

        expect(response).to have_http_status(:bad_request)
      end

      it "returns JSON with success false" do
        post "/driver/manage_working_status", params: invalid_params

        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
      end
    end

    context "when unauthenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(nil)
      end

      it "redirects to login" do
        post "/driver/manage_working_status", params: valid_start_params

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /driver/handle_request/:id" do
    let(:request_id) { "test-request-123" }

    let(:valid_accept_params) do
      {
        action_type: "accept"
      }
    end

    let(:valid_dismiss_params) do
      {
        action_type: "dismiss"
      }
    end

    before do
      delivery_state = DeliveryState.instance
      delivery_state.set_driver_working(true)
      delivery_state.set_driver_location(-23.5505, -46.6333)
      delivery_state.add_request(request_id, {
        id: request_id,
        name: "John Doe",
        status: "pending"
      })
    end

    context "with valid accept parameters" do
      it "returns http success" do
        post "/driver/handle_request/#{request_id}", params: valid_accept_params

        expect(response).to have_http_status(:success)
      end

      it "calls HandleDeliveryRequest use case" do
        expect(HandleDeliveryRequest).to receive(:call).with(
          request_id: request_id,
          action: "accept"
        ).and_call_original

        post "/driver/handle_request/#{request_id}", params: valid_accept_params
      end
    end

    context "with valid dismiss parameters" do
      it "returns http success" do
        post "/driver/handle_request/#{request_id}", params: valid_dismiss_params

        expect(response).to have_http_status(:success)
      end
    end

    context "with nonexistent request" do
      it "returns bad request status" do
        post "/driver/handle_request/nonexistent", params: valid_accept_params

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when unauthenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(nil)
      end

      it "redirects to login" do
        post "/driver/handle_request/#{request_id}", params: valid_accept_params

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /driver/update_location" do
    let(:valid_params) do
      {
        lat: "-23.5600",
        long: "-46.6400"
      }
    end

    let(:invalid_params) do
      {
        lat: nil,
        long: nil
      }
    end

    before do
      delivery_state = DeliveryState.instance
      delivery_state.set_driver_working(true)
    end

    context "with valid parameters" do
      it "returns http success" do
        patch "/driver/update_location", params: valid_params

        expect(response).to have_http_status(:success)
      end

      it "calls UpdateDriverLocation use case" do
        expect(UpdateDriverLocation).to receive(:call).with(
          lat: -23.5600,
          long: -46.6400
        ).and_call_original

        patch "/driver/update_location", params: valid_params
      end
    end

    context "with invalid parameters" do
      it "returns bad request status" do
        patch "/driver/update_location", params: invalid_params

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when driver is not working" do
      before do
        delivery_state = DeliveryState.instance
        delivery_state.set_driver_working(false)
      end

      it "returns bad request status" do
        patch "/driver/update_location", params: valid_params

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when unauthenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(nil)
      end

      it "redirects to login" do
        patch "/driver/update_location", params: valid_params

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
