# frozen_string_literal: true

allowed_hosts = []

# Allow connections to the Selenium server and the Rails app
if ENV['SELENIUM_HOST']
  allowed_hosts << ENV.fetch('SELENIUM_HOST')
  # This hostname is defined for devcontainers
  allowed_hosts << 'rails-app'
end

WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_hosts)
