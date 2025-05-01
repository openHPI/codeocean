# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # Adjust the save path for screenshots. These are also uploaded as artifacts in GitHub actions.
    Capybara.save_path = Rails.root.join('tmp/screenshots')

    # Clean up the save path with old assets before running the test suite.
    FileUtils.rm_rf(Dir.glob("#{Capybara.save_path}/*"))
  end

  config.before(:each, type: :system) do
    # rack_test by default, for performance
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # Selenium when we need JavaScript
    if ENV['CAPYBARA_SERVER_PORT']
      served_by host: 'rails-app', port: ENV['CAPYBARA_SERVER_PORT']

      driven_by :selenium, using: :headless_chrome, options: {
        browser: :remote,
        url: URI::HTTP.build(host: ENV.fetch('SELENIUM_HOST', nil), port: 4444).to_s,
      }, &chrome_options
    else
      driven_by :selenium, using: :"#{display_mode}#{browser}", &send(:"#{browser}_options")
    end
  end

  private

  def mac_os?
    Gem::Platform.local.os == 'darwin'
  end

  def browser
    return @browser if defined?(@browser)
    # Vagrant currently supports Firefox only.
    return @browser = 'firefox' if ENV.fetch('USER', nil) == 'vagrant'

    case ENV.fetch('BROWSER', 'chrome')
      when /^chrom(e|ium)$/i
        @browser = 'chrome'
      when /^(firefox|iceweasel|gecko)$/i
        @browser = 'firefox'
    end
  end

  def display_mode
    return @display_mode if defined?(@display_mode)

    if enabled?('CI') || enabled?('HEADLESS') || ENV.fetch('USER', nil) == 'vagrant'
      @display_mode = 'headless_'
    else
      @display_mode = ''
    end
  end

  def enabled?(env_key, default_value = '0')
    %w[0 n no off false f].exclude?(ENV.fetch(env_key, default_value).downcase)
  end

  def chrome_options
    lambda {|driver_options|
      # Since Chrome 127, the browser will prompt the user to choose a search engine.
      driver_options.add_argument('disable-search-engine-choice-screen')
      # We need to sync the browser's locale with the one used by the testing framework.
      driver_options.add_argument("accept-lang=#{I18n.locale}")
    }
  end

  def firefox_options
    lambda {|driver_options|
      # We need to sync the browser's locale with the one used by the testing framework.
      driver_options.add_preference('intl.accept_languages', I18n.locale)
    }
  end
end
