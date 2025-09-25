class Driver::BaseController < ApplicationController
  before_action :require_authentication
end
