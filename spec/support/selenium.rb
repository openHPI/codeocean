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
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(elementScrollBehavior: 1)
  options = Selenium::WebDriver::Firefox::Options.new
  options.profile = profile
  driver = Capybara::Selenium::Driver.new(app, browser: :firefox, desired_capabilities: capabilities, options: options)
  driver.browser.manage.window.resize_to(1280, 960)
  driver
end
Capybara.javascript_driver = :selenium
