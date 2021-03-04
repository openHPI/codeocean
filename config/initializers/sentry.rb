# frozen_string_literal: true

Sentry.init do |config|
  # Do not send full list of gems with each event
  config.send_modules = false

  # Send some more data, such as request bodies
  config.send_default_pii = true

  # Strip sensitive user data such as passwords from event annotations
  filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    event.request.data = filter.filter(event.request.data)
    event
  end
end
