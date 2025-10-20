require "rails_helper"
RSpec.describe HandleDeliveryRequest do
  let(:delivery_state) { DeliveryState.instance }
  before do
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(true)
    delivery_state.set_driver_location(-23.5505, -46.6333)
  end

  describe "#call" do
    let(:request_data) do
      {
        id: "test-request-123",
        name: "John Doe",
        address: "Rua Teste, 123",
        lat: -23.5489,
        long: -46.6388,
        status: "pending",
        requested_at: Time.current
      }
    end

    let(:accepted_request_data) do
      {
        id: "accepted-request-456",
        name: "Jane Smith",
        address: "Avenida Paulista, 1000",
        lat: -23.5629,
        long: -46.6544,
        status: "accepted",
        requested_at: Time.current
      }
    end

    before do
      delivery_state.add_request("test-request-123", request_data)
    end

    context "when accepting a request" do
      let(:accept_params) do
        {
          request_id: "test-request-123",
          action: "accept"
        }
      end

      context "with valid conditions" do
        it "returns success result" do
          result = described_class.call(accept_params)
          expect(result).to be_success
          expect(result.value[:message]).to eq("Request accepted")
        end

        it "updates request status to accepted" do
          described_class.call(accept_params)
          updated_request = delivery_state.get_request("test-request-123")
          expect(updated_request[:status]).to eq("accepted")
        end

        it "broadcasts acceptance to customer" do
          expect {
            described_class.call(accept_params)
          }.to have_broadcasted_to("customer_test-request-123").with(
            hash_including(
              type: "request_accepted",
              message: "Driver is on the way!",
              driver_location: hash_including(
                lat: -23.5505,
                long: -46.6333
              )
            )
          )
        end

        it "returns updated request in result" do
          result = described_class.call(accept_params)
          expect(result.value[:request]).to include(
            id: "test-request-123",
            status: "accepted"
          )
        end
      end

      context "when request is already accepted" do
        before do
          delivery_state.add_request("accepted-request-456", accepted_request_data)
        end

        let(:already_accepted_params) do
          {
            request_id: "accepted-request-456",
            action: "accept"
          }
        end

        it "returns failure result" do
          result = described_class.call(already_accepted_params)
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Request is no longer pending")
        end

        it "does not broadcast" do
          expect {
            described_class.call(already_accepted_params)
          }.not_to have_broadcasted_to("customer_accepted-request-456")
        end
      end

      context "when driver location is unknown" do
        before do
          delivery_state.instance_variable_set(:@driver, { status: true, location: nil })
        end

        it "returns failure result" do
          result = described_class.call(accept_params)
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Driver location unknown")
        end
      end
    end

    context "when dismissing a request" do
      let(:dismiss_params) do
        {
          request_id: "test-request-123",
          action: "dismiss"
        }
      end

      it "returns success result" do
        result = described_class.call(dismiss_params)
        expect(result).to be_success
        expect(result.value[:message]).to eq("Request dismissed")
      end

      it "removes request from delivery state" do
        described_class.call(dismiss_params)
        expect(delivery_state.get_request("test-request-123")).to be_nil
      end

      context "when request was pending" do
        it "broadcasts dismissal to customer" do
          expect {
            described_class.call(dismiss_params)
          }.to have_broadcasted_to("customer_test-request-123").with(
            hash_including(
              type: "request_dismissed",
              message: "Your request has been dismissed. Please try again later."
            )
          )
        end
      end

      context "when request was already accepted" do
        before do
          delivery_state.update_request_status("test-request-123", "accepted")
        end

        it "still removes the request but does not broadcast dismissal" do
          expect {
            described_class.call(dismiss_params)
          }.not_to have_broadcasted_to("customer_test-request-123")
          expect(delivery_state.get_request("test-request-123")).to be_nil
        end
      end

      it "returns dismissed request in result" do
        result = described_class.call(dismiss_params)
        expect(result.value[:request]).to include(
          id: "test-request-123",
          name: "John Doe"
        )
      end
    end

    context "when request does not exist" do
      let(:nonexistent_params) do
        {
          request_id: "nonexistent-request",
          action: "accept"
        }
      end

      it "returns failure result" do
        result = described_class.call(nonexistent_params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Request not found")
      end

      it "does not broadcast" do
        expect {
          described_class.call(nonexistent_params)
        }.not_to have_broadcasted_to("customer_nonexistent-request")
      end
    end

    context "when driver is not working" do
      before do
        delivery_state.set_driver_working(false)
      end

      let(:offline_params) do
        {
          request_id: "test-request-123",
          action: "accept"
        }
      end

      it "returns failure result" do
        result = described_class.call(offline_params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Driver not available")
      end

      it "does not change request status" do
        original_request = delivery_state.get_request("test-request-123")
        described_class.call(offline_params)
        updated_request = delivery_state.get_request("test-request-123")
        expect(updated_request[:status]).to eq(original_request[:status])
      end
    end

    context "with invalid action" do
      let(:invalid_action_params) do
        {
          request_id: "test-request-123",
          action: "invalid_action"
        }
      end

      it "returns failure result" do
        result = described_class.call(invalid_action_params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Invalid action: invalid_action")
      end

      it "does not change request" do
        original_request = delivery_state.get_request("test-request-123")
        described_class.call(invalid_action_params)
        updated_request = delivery_state.get_request("test-request-123")
        expect(updated_request).to eq(original_request)
      end
    end

    context "edge cases" do
      it "handles nil action" do
        params = {
          request_id: "test-request-123",
          action: nil
        }
        result = described_class.call(params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Invalid action: ")
      end

      it "handles empty string action" do
        params = {
          request_id: "test-request-123",
          action: ""
        }
        result = described_class.call(params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Invalid action: ")
      end

      it "handles symbol actions" do
        params = {
          request_id: "test-request-123",
          action: :accept
        }
        result = described_class.call(params)
        expect(result).to be_success
        expect(result.value[:message]).to eq("Request accepted")
      end

      context "with race conditions" do
        let(:request_id) { "test-request-123" }

        it "handles request being accepted by another process" do
          delivery_state.update_request_status(request_id, "accepted")
          result = HandleDeliveryRequest.call(
            request_id: request_id,
            action: "accept"
          )
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Request is no longer pending")
        end

        it "handles request being deleted during processing" do
          delivery_state.remove_request(request_id)
          result = HandleDeliveryRequest.call(
            request_id: request_id,
            action: "accept"
          )
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Request not found")
        end
      end

      context "with invalid request states" do
        let(:request_id) { "test-request-123" }

        it "handles requests with invalid status" do
          delivery_state.update_request_status(request_id, "invalid_status")
          result = HandleDeliveryRequest.call(
            request_id: request_id,
            action: "accept"
          )
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Request is no longer pending")
        end

        it "handles malformed request data" do
          malformed_id = "malformed-request"
          delivery_state.add_request(malformed_id, {
            id: malformed_id,
            status: "pending"
          })
          result = HandleDeliveryRequest.call(
            request_id: malformed_id,
            action: "accept"
          )
          expect(result).to be_success
        end
      end

      context "with case sensitivity" do
        let(:request_id) { "test-request-123" }

        it "handles case-insensitive actions" do
          result = HandleDeliveryRequest.call(
            request_id: request_id,
            action: "ACCEPT"
          )
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Invalid action: ACCEPT")
        end
      end
    end
  end
end
