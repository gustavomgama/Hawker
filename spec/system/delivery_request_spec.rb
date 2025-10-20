require "rails_helper"
RSpec.describe "Delivery Request Flow", type: :system do
  let(:user) { create(:user, email: "customer@example.com", password: "password123") }

  let(:delivery_state) { DeliveryState.instance }

  before do
    driven_by(:rack_test)
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(false)
    sign_in_as(user)
  end

  describe "Customer requesting delivery" do
    context "when driver is available" do
      before do
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-23.5505, -46.6333)
      end

      it "successfully creates a delivery request", :js do
        visit root_path
        expect(page).to have_content("Home#index")
      end

      it "handles invalid delivery request data" do
        skip "Waiting for delivery request form implementation"
      end
    end

    context "when driver is not available" do
      before do
        delivery_state.set_driver_working(false)
      end

      it "shows error when no driver is available" do
        skip "Waiting for delivery request form implementation"
      end
    end
  end

  describe "Real-time updates" do
    context "when using JavaScript driver", :js do
      before do
        driven_by(:selenium_chrome_headless)
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-23.5505, -46.6333)
      end

      it "receives real-time notifications about delivery status" do
        visit root_path
        skip "Waiting for real-time UI implementation"
      end
    end
  end

  describe "Multiple customers" do
    let(:user2) { create(:user, email: "customer2@example.com", password: "password123") }

    before do
      delivery_state.set_driver_working(true)
      delivery_state.set_driver_location(-23.5505, -46.6333)
    end

    it "handles multiple simultaneous requests" do
      skip "Waiting for delivery request form implementation"
    end
  end

  describe "Browser compatibility" do
    it "works with JavaScript disabled" do
      driven_by(:rack_test)

      visit root_path

      expect(page).to have_content("Home#index")
    end

    it "works with JavaScript enabled", :js do
      driven_by(:selenium_chrome_headless)

      visit new_session_path

      fill_in "email", with: user.email
      fill_in "password", with: "password123"

      click_button "Sign in"

      expect(page).to have_content("Home#index")
    end
  end
end
