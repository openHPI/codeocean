# frozen_string_literal: true

Sentry.init do |config|
  # Do not send full list of gems with each event
  config.send_modules = false

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.01
end
