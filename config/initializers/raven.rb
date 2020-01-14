# frozen_string_literal: true

require 'concurrent'

Rails.application.tap do |app|
  pool = ::Concurrent::ThreadPoolExecutor.new(max_queue: 10)

  Raven.configure do |config|
    config.sanitize_fields = app.config.filter_parameters.map(&:to_s)

    config.async = lambda do |event|
      pool.post { ::Raven.send_event(event) }
    end

    # Do not sent full list of gems with each event
    config.send_modules = false
  end
end
