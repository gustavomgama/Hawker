module SystemTestHelpers
  def sign_in_as(user)
    visit new_session_path
    fill_in "email", with: user.email
    fill_in "password", with: user.password || "password123"
    click_button "Sign in"
  end

  def sign_out
    page.driver.submit :delete, session_path, {}
  end
end

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
end
