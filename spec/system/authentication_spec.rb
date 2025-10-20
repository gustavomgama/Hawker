require "rails_helper"
RSpec.describe "User Authentication", type: :system do
  let(:user) { create(:user, email: "test@example.com", password: "password123") }

  before do
    driven_by(:rack_test)
  end

  describe "Sign in" do
    it "allows a user to sign in with valid credentials" do
      visit new_session_path

      expect(page).to have_content("Sign in")
      expect(page).to have_field("email")
      expect(page).to have_field("password")

      fill_in "email", with: user.email
      fill_in "password", with: "password123"

      click_button "Sign in"

      expect(page).to have_current_path(root_path)
      expect(page).not_to have_content("Sign in")
    end

    it "shows error message with invalid credentials" do
      visit new_session_path

      fill_in "email", with: user.email
      fill_in "password", with: "wrong_password"

      click_button "Sign in"

      expect(page).to have_current_path(new_session_path, ignore_query: true)
      expect(page).to have_content("Try another email address or password.")
    end

    it "shows error message with non-existent email" do
      visit new_session_path

      fill_in "email", with: "nonexistent@example.com"
      fill_in "password", with: "password123"

      click_button "Sign in"

      expect(page).to have_current_path(new_session_path, ignore_query: true)
      expect(page).to have_content("Try another email address or password.")
    end

    it "requires email field" do
      visit new_session_path

      fill_in "password", with: "password123"

      click_button "Sign in"

      expect(page).to have_content("Try another email address or password.")
    end

    it "requires password field" do
      visit new_session_path

      fill_in "email", with: user.email

      click_button "Sign in"

      expect(page).to have_content("Try another email address or password.")
    end

    it "has a link to password reset" do
      visit new_session_path

      expect(page).to have_link("Forgot password?", href: new_password_path)
    end
  end

  describe "Sign out" do
    before do
      visit new_session_path

      fill_in "email", with: user.email
      fill_in "password", with: "password123"

      click_button "Sign in"
    end

    it "allows a user to sign out" do
      page.driver.submit :delete, session_path, {}

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Sign in")
    end
  end

  describe "Session persistence" do
    it "keeps user signed in across page visits" do
      visit new_session_path

      fill_in "email", with: user.email
      fill_in "password", with: "password123"

      click_button "Sign in"

      visit root_path

      expect(page).not_to have_content("Sign in")

      visit driver_root_path

      expect(page).not_to have_content("Sign in")
    end
  end

  describe "Access control" do
    it "redirects unauthenticated users to sign in" do
      visit driver_root_path

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Sign in")
    end
  end
end
