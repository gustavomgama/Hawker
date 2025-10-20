require "rails_helper"
RSpec.describe CreateDeliveryRequest do
  let(:delivery_state) { DeliveryState.instance }

  before do
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver_status, Concurrent::Hash.new)
    delivery_state.set_driver_working(false)
  end

  describe "#call" do
    let(:valid_params) do
      {
        name: "John Doe",
        address: "Rua Teste",
        lat: -11,
        long: -33
      }
    end

    let(:invalid_params) do
      {
        name: nil,
        address: nil,
        lat: nil,
        long: nil
      }
    end

    context "with valid conditions" do
      before do
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-11, -33)
      end

      it "returns success result" do
        result = described_class.call(valid_params)

        expect(result).to be_success
        expect(result.value[:message]).to eq("Request sent!")
      end

      it "stores request in delivery state with correct attributes" do
        result = described_class.call(valid_params)
        request_id = result.value[:request][:id]
        stored_request = delivery_state.get_request(request_id)

        expect(stored_request).to include(
          id: request_id,
          name: "John Doe",
          address: "Rua Teste",
          lat: -11,
          long: -33,
          status: "pending"
        )
        expect(stored_request[:requested_at]).to be_within(1.second).of Time.current
      end

      it "broadcasts to driver channel" do
        expect {
          described_class.call(valid_params)
        }.to have_broadcasted_to("driver_channel").with(
        hash_including(
          type: "new_request",
            request: hash_including(
              name: "John Doe",
              address: "Rua Teste",
              status: "pending"
            )
          )
        )
      end

      it "returns the complete request data in result" do
        result = described_class.call(valid_params)
        request = result.value[:request]

        expect(request).to include(
          name: "John Doe",
          address: "Rua Teste",
          lat: -11,
          long: -33,
          status: "pending"
        )
      end
    end

    context "with invalid conditions" do
      it "returns invalid input data result" do
        result = described_class.call(invalid_params)

        expect(result).to be_failure
        expect(result.value[:error]).to eq("Invalid input data")
      end

      it "does not broadcast" do
        expect {
          described_class.call(invalid_params)
        }.not_to have_broadcasted_to("driver_channel")
      end

      it "does not store request" do
        expect {
          described_class.call(invalid_params)
        }.not_to change { delivery_state.all_requests.count }
      end
    end

    context "when driver is not working" do
      before do
        delivery_state.set_driver_working(false)
      end

      it "returns driver offline" do
        result = described_class.call(valid_params)

        expect(result).to be_failure
        expect(result.value[:error]).to eq("No driver available")
      end

      it "does not broadcast" do
        expect {
          described_class.call(valid_params)
        }.not_to have_broadcasted_to("driver_channel")
      end
    end

    context "edge cases" do
      context "with extreme precision coordinates" do
        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles high precision GPS coordinates" do
          result = CreateDeliveryRequest.call(
            name: "Precision Test",
            address: "High Precision Address",
            lat: -23.55055555555555555555,
            long: -46.63333333333333333333
          )

          expect(result).to be_success
          expect(result.value[:request][:lat]).to be_within(0.0001).of(-23.5506)
          expect(result.value[:request][:long]).to be_within(0.0001).of(-46.6333)
        end

        it "handles zero coordinates" do
          result = CreateDeliveryRequest.call(
            name: "Zero Test",
            address: "Null Island",
            lat: 0.0,
            long: 0.0
          )

          expect(result).to be_success
          expect(result.value[:request][:lat]).to eq(0.0)
          expect(result.value[:request][:long]).to eq(0.0)
        end

        it "handles negative zero coordinates" do
          result = CreateDeliveryRequest.call(
            name: "Negative Zero Test",
            address: "Negative Null Island",
            lat: -0.0,
            long: -0.0
          )

          expect(result).to be_success
          expect(result.value[:request][:lat]).to eq(0.0)
          expect(result.value[:request][:long]).to eq(0.0)
        end
      end

      context "with floating point edge cases" do
        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles very small numbers" do
          result = CreateDeliveryRequest.call(
            name: "Small Number Test",
            address: "Tiny Address",
            lat: 0.000001,
            long: -0.000001
          )

          expect(result).to be_success
          expect(result.value[:request][:lat]).to eq(0.000001)
        end

        it "handles scientific notation" do
          result = CreateDeliveryRequest.call(
            name: "Scientific Test",
            address: "Science Address",
            lat: 1e-10,
            long: -1e-10
          )

          expect(result).to be_success
        end

        it "handles infinity values (system currently accepts them)" do
          result = CreateDeliveryRequest.call(
            name: "Infinity Test",
            address: "Infinite Address",
            lat: Float::INFINITY,
            long: -Float::INFINITY
          )

          expect(result).to be_success
          expect(result.value[:request][:lat]).to eq(Float::INFINITY)
          expect(result.value[:request][:long]).to eq(-Float::INFINITY)
        end

        it "handles NaN values (system currently accepts them)" do
          result = CreateDeliveryRequest.call(
            name: "NaN Test",
            address: "Not a Number Address",
            lat: Float::NAN,
            long: Float::NAN
          )

          expect(result).to be_success
          expect(result.value[:request][:lat].nan?).to be true
          expect(result.value[:request][:long].nan?).to be true
        end
      end

      context "with string edge cases" do
        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
        end

        it "handles strings with only whitespace" do
          result = CreateDeliveryRequest.call(
            name: "   \t\n   ",
            address: "   \t\n   ",
            lat: -23.5505,
            long: -46.6333
          )

          expect(result).to be_failure
          expect(result.value[:error]).to eq("Invalid input data")
        end

        it "trims whitespace from valid strings" do
          result = CreateDeliveryRequest.call(
            name: "  Valid Name  ",
            address: "  Valid Address  ",
            lat: -23.5505,
            long: -46.6333
          )

          expect(result).to be_success
          expect(result.value[:request][:name]).to eq("Valid Name")
          expect(result.value[:request][:address]).to eq("Valid Address")
        end

        it "handles mixed whitespace characters" do
          result = CreateDeliveryRequest.call(
            name: "\t\nValid\r\n Name\t",
            address: "\r\nValid\t Address\n",
            lat: -23.5505,
            long: -46.6333
          )

          expect(result).to be_success
          expect(result.value[:request][:name]).to eq("Valid\r\n Name")
          expect(result.value[:request][:address]).to eq("Valid\t Address")
        end
      end

      context "with concurrent driver state changes" do
        it "handles driver going offline during request creation" do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)
          allow(delivery_state).to receive(:driver_working?).and_return(false)

          result = CreateDeliveryRequest.call(
            name: "Concurrent Test",
            address: "Concurrent Address",
            lat: -23.5505,
            long: -46.6333
          )

          expect(result).to be_failure
          expect(result.value[:error]).to eq("No driver available")
        end
      end
    end
  end
end
