# frozen_string_literal: true

require 'capybara/rspec'
require 'selenium/webdriver'

if ENV.fetch('HEADLESS_TEST', nil) == 'true' || ENV.fetch('USER', nil) == 'vagrant'
  require 'headless'

  headless = Headless.new
  headless.start
end

Capybara.register_driver :selenium do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.accept_languages'] = 'en'
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument('-headless') if ENV.fetch('CI', nil) == 'true'
  options.profile = profile
  driver = Capybara::Selenium::Driver.new(app, browser: :firefox, options:)
  driver.browser.manage.window.resize_to(1280, 960)
  driver
end
Capybara.javascript_driver = :selenium

# Specify to use puma as server and disable debug output
Capybara.server = :puma, {Silent: true}
