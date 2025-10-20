require "rails_helper"

RSpec.describe DriverChannel, type: :channel do
  let(:user) { create(:user) }

  let(:session_record) { create(:session, user: user) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "successfully subscribes to the driver stream when authenticated" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("driver_channel")
    end

    it "rejects subscription when not authenticated" do
      stub_connection current_user: nil

      subscribe

      expect(subscription).to be_rejected
    end
  end

  describe "#unsubscribed" do
    it "stops all streams when unsubscribed" do
      subscribe
      expect(subscription).to be_confirmed

      unsubscribe
      expect(subscription).not_to have_streams
    end
  end

  describe "receiving broadcasts" do
    before do
      subscribe
    end

    it "receives driver status updates" do
      status_data = {
        type: "status_update",
        working: true,
        location: { lat: -23.5505, long: -46.6333 }
      }

      expect {
        ActionCable.server.broadcast("driver_channel", status_data)
      }.to have_broadcasted_to("driver_channel").with(status_data)
    end

    it "receives new delivery request notifications" do
      request_data = {
        type: "new_request",
        request: {
          id: "test-123",
          name: "John Doe",
          pickup_location: "123 Main St",
          delivery_location: "456 Oak Ave"
        }
      }

      expect {
        ActionCable.server.broadcast("driver_channel", request_data)
      }.to have_broadcasted_to("driver_channel").with(request_data)
    end

    it "receives request cancellations" do
      cancellation_data = {
        type: "request_cancelled",
        request_id: "test-123",
        message: "Customer cancelled the request"
      }

      expect {
        ActionCable.server.broadcast("driver_channel", cancellation_data)
      }.to have_broadcasted_to("driver_channel").with(cancellation_data)
    end
  end
end
