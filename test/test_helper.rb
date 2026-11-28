ENV["RAILS_ENV"] ||= "test"
ENV["HAWKER_USERNAME"] ||= "hawker"
ENV["HAWKER_PASSWORD"] ||= "secret"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  def profile
    HawkerProfile.instance
  end

  def hawker_auth(user: ENV["HAWKER_USERNAME"], password: ENV["HAWKER_PASSWORD"])
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  end
end
