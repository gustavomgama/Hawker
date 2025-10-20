require "rails_helper"
RSpec.describe GetDriverDashboard do
  let(:delivery_state) { DeliveryState.instance }
  before do
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(false)
  end

  describe "#call" do
    it "returns success result" do
      result = described_class.call

      expect(result).to be_success
    end

    context "when driver is not working" do
      before do
        delivery_state.set_driver_working(false)
      end

      it "returns driver offline" do
        result = described_class.call

        expect(result.value[:working]).to be false
      end

      it "returns nil location" do
        result = described_class.call

        expect(result.value[:location]).to be_nil
      end

      it "returns pending requests" do
        result = described_class.call

        expect(result.value[:pending_requests]).to eq([])
      end

      it "returns accepted requests" do
        result = described_class.call

        expect(result.value[:accepted_requests]).to eq([])
      end
    end

    context "when driver is working" do
      before do
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-11, -33)
      end

      it "returns driver online" do
        result = described_class.call

        expect(result.value[:working]).to be true
      end
    end

    context "edge cases" do
      context "with large numbers of requests" do
        before do
          delivery_state.set_driver_working(true)
          delivery_state.set_driver_location(-23.5505, -46.6333)

          100.times do |i|
            delivery_state.add_request("bulk-#{i}", {
              id: "bulk-#{i}",
              name: "Bulk User #{i}",
              status: i.even? ? "pending" : "accepted",
              requested_at: Time.current - i.minutes,
              accepted_at: i.odd? ? (Time.current - (i-1).minutes) : nil
            })
          end
        end

        it "handles large datasets efficiently" do
          expect {
            result = GetDriverDashboard.call
            expect(result).to be_success
          }.not_to raise_error

          result = GetDriverDashboard.call

          dashboard_data = result.value

          expect(dashboard_data[:pending_requests].length).to eq(50)
          expect(dashboard_data[:accepted_requests].length).to eq(50)
        end

        it "sorts requests correctly by time" do
          result = GetDriverDashboard.call
          dashboard_data = result.value

          pending_times = dashboard_data[:pending_requests].map { |r| r[:requested_at] }
          expect(pending_times).to eq(pending_times.sort)

          accepted_times = dashboard_data[:accepted_requests].map { |r| r[:accepted_at] || r[:requested_at] }
          expect(accepted_times).to eq(accepted_times.sort)
        end
      end

      context "with malformed request data" do
        before do
          delivery_state.set_driver_working(true)

          delivery_state.add_request("no-time", {
            id: "no-time",
            name: "No Time User",
            status: "pending"
          })

          delivery_state.add_request("bad-time", {
            id: "bad-time",
            name: "Bad Time User",
            status: "accepted",
            requested_at: "invalid-time",
            accepted_at: "also-invalid"
          })
        end

        it "handles missing timestamps gracefully" do
          expect {
            result = GetDriverDashboard.call
            expect(result).to be_success
          }.not_to raise_error
        end
      end
    end
  end
end
