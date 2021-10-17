# frozen_string_literal: true

require 'capybara/rspec'
require 'selenium/webdriver'

if ENV['HEADLESS_TEST'] == 'true' || ENV['USER'] == 'vagrant'
  require 'headless'

  headless = Headless.new
  headless.start
end

Capybara.register_driver :selenium do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.accept_languages'] = 'en'
  options = Selenium::WebDriver::Firefox::Options.new
  options.headless! if ENV['CI'] == 'true'
  options.profile = profile
  driver = Capybara::Selenium::Driver.new(app, browser: :firefox, capabilities: options)
  driver.browser.manage.window.resize_to(1280, 960)
  driver
end
Capybara.javascript_driver = :selenium
