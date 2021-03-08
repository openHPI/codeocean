# frozen_string_literal: true

Sentry.init do |config|
  # Do not send full list of gems with each event
  config.send_modules = false
end
