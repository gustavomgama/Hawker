if Rails.env.development?
  require "prosopite/middleware/rack"
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)
end

Rails.application.config.after_initialize do
  if Rails.env.development?
    Prosopite.add_footer = true
  elsif Rails.env.test?
    Prosopite.raise = true
  end
end
