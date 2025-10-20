require "rails_helper"
RSpec.describe ManageDriverStatus do
  let(:delivery_state) { DeliveryState.instance }
  before do
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(false)
  end

  describe "#call" do
    let(:valid_location_params) do
      {
        action: "start_working",
        lat: -23.5505,
        long: -46.6333
      }
    end

    let(:invalid_location_params) do
      {
        action: "start_working",
        lat: nil,
        long: nil
      }
    end

    context "when starting to work" do
      context "with valid location" do
        it "returns success result" do
          result = described_class.call(valid_location_params)
          expect(result).to be_success
          expect(result.value[:message]).to eq("You're now working!")
        end

        it "sets driver working status to true" do
          described_class.call(valid_location_params)
          expect(delivery_state.driver_working?).to be true
        end

        it "sets driver location" do
          described_class.call(valid_location_params)
          location = delivery_state.driver_location
          expect(location[:lat]).to eq(-23.5505)
          expect(location[:long]).to eq(-46.6333)
          expect(location[:updated_at]).to be_within(1.second).of Time.current
        end

        it "broadcasts driver online status to all customers" do
          expect {
            described_class.call(valid_location_params)
          }.to have_broadcasted_to("customer_updates").with(
            hash_including(
              type: "driver_online",
              location: hash_including(
                lat: -23.5505,
                long: -46.6333
              )
            )
          )
        end

        it "returns working status and location in result" do
          result = described_class.call(valid_location_params)
          expect(result.value).to include(
            working: true,
            location: { lat: -23.5505, long: -46.6333 }
          )
        end
      end

      context "with invalid location" do
        it "returns failure result" do
          result = described_class.call(invalid_location_params)
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Valid location required to start working ")
        end

        it "does not set driver working status" do
          described_class.call(invalid_location_params)
          expect(delivery_state.driver_working?).to be false
        end

        it "does not broadcast" do
          expect {
            described_class.call(invalid_location_params)
          }.not_to have_broadcasted_to("customer_updates")
        end
      end
    end

    context "when stopping work" do
      let(:stop_working_params) { { action: "stop_working" } }
      before do
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-23.5505, -46.6333)
        delivery_state.add_request("req1", { id: "req1", status: "pending" })
        delivery_state.add_request("req2", { id: "req2", status: "pending" })
        delivery_state.add_request("req3", { id: "req3", status: "accepted" })
      end

      it "returns success result" do
        result = described_class.call(stop_working_params)
        expect(result).to be_success
        expect(result.value[:message]).to eq("You're now offline")
      end

      it "sets driver working status to false" do
        described_class.call(stop_working_params)
        expect(delivery_state.driver_working?).to be false
      end

      it "clears all pending requests" do
        expect {
          described_class.call(stop_working_params)
        }.to change { delivery_state.pending_requests.count }.from(2).to(0)
      end

      it "does not affect accepted requests" do
        described_class.call(stop_working_params)
        expect(delivery_state.get_request("req3")).not_to be_nil
        expect(delivery_state.get_request("req3")[:status]).to eq("accepted")
      end

      it "broadcasts dismissal to each pending request customer" do
        expect {
          described_class.call(stop_working_params)
        }.to have_broadcasted_to("customer_req1").with(
          hash_including(
            type: "request_dismissed",
            message: "Driver is no longer available. Please try again later."
          )
        ).and have_broadcasted_to("customer_req2").with(
          hash_including(
            type: "request_dismissed",
            message: "Driver is no longer available. Please try again later."
          )
        )
      end

      it "broadcasts driver offline status to all customers" do
        expect {
          described_class.call(stop_working_params)
        }.to have_broadcasted_to("customer_updates").with(
          hash_including(
            type: "driver_offline",
            message: "Driver is no longer available"
          )
        )
      end

      it "returns count of dismissed requests" do
        result = described_class.call(stop_working_params)
        expect(result.value).to include(
          working: false,
          dismissed_requests: 2
        )
      end
    end

    context "with invalid action" do
      let(:invalid_action_params) { { action: "invalid_action" } }

      it "returns failure result" do
        result = described_class.call(invalid_action_params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Invalid action: invalid_action")
      end

      it "does not change driver status" do
        original_status = delivery_state.driver_working?
        described_class.call(invalid_action_params)
        expect(delivery_state.driver_working?).to eq(original_status)
      end
    end

    context "edge cases" do
      it "handles string coordinates correctly" do
        params = {
          action: "start_working",
          lat: "-23.5505",
          long: "-46.6333"
        }
        result = described_class.call(params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Valid location required to start working ")
      end

      it "handles zero coordinates correctly" do
        params = {
          action: "start_working",
          lat: 0.0,
          long: 0.0
        }
        result = described_class.call(params)
        expect(result).to be_success
        expect(delivery_state.driver_location[:lat]).to eq(0.0)
        expect(delivery_state.driver_location[:long]).to eq(0.0)
      end

      context "with boundary coordinates" do
        it "handles minimum valid coordinates" do
          result = ManageDriverStatus.call(
            action: "start_working",
            lat: -90.0,
            long: -180.0
          )
          expect(result).to be_success
          location = delivery_state.driver_location
          expect(location[:lat]).to eq(-90.0)
          expect(location[:long]).to eq(-180.0)
          expect(location).to have_key(:updated_at)
        end

        it "handles maximum valid coordinates" do
          result = ManageDriverStatus.call(
            action: "start_working",
            lat: 90.0,
            long: 180.0
          )
          expect(result).to be_success
          location = delivery_state.driver_location
          expect(location[:lat]).to eq(90.0)
          expect(location[:long]).to eq(180.0)
          expect(location).to have_key(:updated_at)
        end

        it "still accepts out-of-bounds coordinates (no validation)" do
          result = ManageDriverStatus.call(
            action: "start_working",
            lat: 91.0,
            long: 181.0
          )
          expect(result).to be_success
          location = delivery_state.driver_location
          expect(location[:lat]).to eq(91.0)
          expect(location[:long]).to eq(181.0)
          expect(location).to have_key(:updated_at)
        end
      end

      context "with floating point precision" do
        it "maintains coordinate precision" do
          precise_lat = -23.555555555555555
          precise_long = -46.666666666666666
          result = ManageDriverStatus.call(
            action: "start_working",
            lat: precise_lat,
            long: precise_long
          )
          expect(result).to be_success
          stored_location = delivery_state.driver_location
          expect(stored_location[:lat]).to be_within(1e-10).of(precise_lat)
          expect(stored_location[:long]).to be_within(1e-10).of(precise_long)
        end
      end

      context "with existing pending requests" do
        before do
          delivery_state.set_driver_working(true)
          delivery_state.add_request("pending-1", {
            id: "pending-1",
            status: "pending",
            name: "Pending User 1"
          })
          delivery_state.add_request("pending-2", {
            id: "pending-2",
            status: "pending",
            name: "Pending User 2"
          })
          delivery_state.add_request("accepted-1", {
            id: "accepted-1",
            status: "accepted",
            name: "Accepted User 1"
          })
        end

        it "clears only pending requests when stopping work" do
          expect(delivery_state.pending_requests.length).to eq(2)
          expect(delivery_state.all_requests.length).to eq(3)
          result = ManageDriverStatus.call(action: "stop_working")
          expect(result).to be_success
          expect(delivery_state.pending_requests.length).to eq(0)
          remaining_requests = delivery_state.all_requests
          expect(remaining_requests.length).to eq(1)
          expect(remaining_requests.first[:status]).to eq("accepted")
        end

        it "successfully stops working and clears pending requests" do
          pending_count = delivery_state.pending_requests.length
          expect(pending_count).to eq(2)
          result = ManageDriverStatus.call(action: "stop_working")
          expect(result).to be_success
          expect(delivery_state.pending_requests.length).to eq(0)
          expect(result.value).to be_a(Hash)
        end
      end
    end
  end
end
