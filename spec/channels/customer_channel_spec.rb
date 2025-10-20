require "rails_helper"

RSpec.describe CustomerChannel, type: :channel do
  let(:user) { create(:user) }

  let(:session_record) { create(:session, user: user) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "successfully subscribes to the customer updates stream" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("customer_updates")
    end

    it "subscribes to request-specific stream when request_id provided" do
      subscribe(request_id: "test-123")

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("customer_updates")
      expect(subscription).to have_stream_from("customer_test-123")
    end

    it "only subscribes to general updates when no request_id provided" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("customer_updates")
      expect(subscription).not_to have_stream_from("customer_")
    end
  end

  describe "#unsubscribed" do
    it "stops all streams when unsubscribed" do
      subscribe(request_id: "test-123")
      expect(subscription).to be_confirmed

      unsubscribe
      expect(subscription).not_to have_streams
    end
  end

  describe "receiving broadcasts" do
    let(:request_id) { "test-request-123" }

    before do
      subscribe(request_id: request_id)
    end

    it "receives general customer updates" do
      update_data = {
        type: "driver_availability",
        available: true,
        message: "Driver is now online"
      }

      expect {
        ActionCable.server.broadcast("customer_updates", update_data)
      }.to have_broadcasted_to("customer_updates").with(update_data)
    end

    it "receives request-specific updates" do
      request_data = {
        type: "request_accepted",
        request_id: request_id,
        driver_eta: 5
      }

      expect {
        ActionCable.server.broadcast("customer_#{request_id}", request_data)
      }.to have_broadcasted_to("customer_#{request_id}").with(request_data)
    end

    it "receives driver location updates" do
      location_data = {
        type: "location_update",
        lat: -23.5600,
        long: -46.6400,
        timestamp: Time.current.to_i
      }

      expect {
        ActionCable.server.broadcast("customer_updates", location_data)
      }.to have_broadcasted_to("customer_updates").with(location_data)
    end
  end
end
