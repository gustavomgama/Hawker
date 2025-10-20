require "rails_helper"
RSpec.describe UpdateDriverLocation do
  let(:delivery_state) { DeliveryState.instance }
  before do
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver_status, Concurrent::Hash.new)
  end

  describe "#call" do
    let(:valid_params) do
      {
        lat: -11,
        long: -33
      }
    end

    context "when driver is working" do
      before do
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-11, -33)
      end

      it "returns success result" do
        result = described_class.call(valid_params)
        expect(result).to be_success
        expect(result.value[:message]).to eq("Location updated")
      end

      it "updates driver location" do
        described_class.call(valid_params)
        location = delivery_state.driver_location
        expect(location[:lat]).to eq(-11)
        expect(location[:long]).to eq(-33)
      end

      it "updates location timestamp" do
        described_class.call(valid_params)
        location = delivery_state.driver_location
        expect(location[:updated_at]).to be_within(1.second).of Time.current
      end

      it "broadcasts location update to all customers" do
        expect {
          described_class.call(valid_params)
        }.to have_broadcasted_to("customer_updates").with(
        hash_including(
          type: "driver_location_update",
            location: hash_including(
              lat: -11,
              long: -33
            )
          )
        )
      end

      it "returns location and pending requests in result" do
        delivery_state.add_request("req1", { id: "req1", status: "pending" })
        delivery_state.add_request("req2", { id: "req2", status: "pending" })
        result = described_class.call(valid_params)
        expect(result.value[:location]).to eq({ lat: -11, long: -33 })
        expect(result.value[:pending_requests].size).to eq(2)
      end

      it "only includes pending requests" do
        delivery_state.add_request("req1", { id: "req1", status: "pending" })
        delivery_state.add_request("req2", { id: "req2", status: "accepted" })
        result = described_class.call(valid_params)
        expect(result.value[:pending_requests].size).to eq(1)
        expect(result.value[:pending_requests].first[:id]).to eq("req1")
      end
    end

    context "when driver is offline" do
      before do
        delivery_state.set_driver_working(false)
      end

      it "returns failure result" do
        result = described_class.call(valid_params)
        expect(result).to be_failure
        expect(result.value[:error]).to eq("Driver is not working")
      end

      it "does not update location" do
        original_location = delivery_state.driver_location
        described_class.call(valid_params)
        expect(delivery_state.driver_location).to eq(original_location)
      end

      it "does not broadcast" do
        expect {
          described_class.call(valid_params)
        }.not_to have_broadcasted_to("customer_updates")
      end

      context "with invalid input" do
        it "returns failure when params are nil" do
          params = valid_params.merge(lat: nil, long: nil)
          delivery_state.set_driver_working(true)
          result = described_class.call(params)
          expect(result).to be_failure
          expect(result.value[:error]).to eq("Invalid coordinates")
        end
      end
    end

    context "edge cases" do
      context "with rapid location updates" do
        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles multiple rapid updates" do
          locations = [
            [ -23.5510, -46.6340 ],
            [ -23.5515, -46.6350 ],
            [ -23.5520, -46.6360 ],
            [ -23.5525, -46.6370 ],
            [ -23.5530, -46.6380 ]
          ]
          locations.each do |lat, long|
            result = UpdateDriverLocation.call(lat: lat, long: long)
            expect(result).to be_success
          end
          final_location = delivery_state.driver_location
          expect(final_location[:lat]).to eq(-23.5530)
          expect(final_location[:long]).to eq(-46.6380)
        end

        it "maintains location update timestamps" do
          first_time = Time.current
          allow(Time).to receive(:current).and_return(first_time)
          UpdateDriverLocation.call(lat: -23.5510, long: -46.6340)
          first_timestamp = delivery_state.driver_location[:updated_at]
          second_time = first_time + 1.minute
          allow(Time).to receive(:current).and_return(second_time)
          UpdateDriverLocation.call(lat: -23.5520, long: -46.6350)
          second_timestamp = delivery_state.driver_location[:updated_at]
          expect(second_timestamp).to be > first_timestamp
        end
      end

      context "with location precision" do
        before do
          delivery_state.set_driver_working(true)
        end

        it "handles micro-movements" do
          result = UpdateDriverLocation.call(
            lat: -23.550500001,
            long: -46.633300001
          )
          expect(result).to be_success
          location = delivery_state.driver_location
          expect(location[:lat]).to be_within(1e-10).of(-23.550500001)
        end

        it "handles identical location updates" do
          UpdateDriverLocation.call(lat: -23.5505, long: -46.6333)
          result = UpdateDriverLocation.call(lat: -23.5505, long: -46.6333)
          expect(result).to be_success
        end
      end
    end
  end
end
