require "rails_helper"

RSpec.describe CustomerUpdatesChannel, type: :channel do
  let(:user) { create(:user) }

  let(:session_record) { create(:session, user: user) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "successfully subscribes to customer updates stream" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("customer_updates")
    end
  end

  describe "#unsubscribed" do
    it "handles unsubscription gracefully" do
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

    it "receives general customer updates" do
      update_data = {
        type: "driver_availability",
        available: true,
        message: "Driver is now available"
      }

      expect {
        ActionCable.server.broadcast("customer_updates", update_data)
      }.to have_broadcasted_to("customer_updates").with(update_data)
    end

    it "receives delivery status updates" do
      status_data = {
        type: "delivery_status",
        status: "in_progress",
        message: "Your driver is on the way"
      }

      expect {
        ActionCable.server.broadcast("customer_updates", status_data)
      }.to have_broadcasted_to("customer_updates").with(status_data)
    end

    it "receives system notifications" do
      notification_data = {
        type: "system_notification",
        message: "Service will be temporarily unavailable"
      }

      expect {
        ActionCable.server.broadcast("customer_updates", notification_data)
      }.to have_broadcasted_to("customer_updates").with(notification_data)
    end
  end
end
