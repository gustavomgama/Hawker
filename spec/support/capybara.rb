require "capybara/rspec"
require "capybara/rails"
require "selenium/webdriver"

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_driver = :rack_test

Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }

Capybara.server_host = "localhost"
Capybara.server_port = 3001
