# frozen_string_literal: true

module WaitForAjax
  def wait_for_ajax
    start_time = Time.current
    timeout = Capybara.default_max_wait_time

    loop do
      break if ajax_requests_finished? || (Time.current - start_time) > timeout

      sleep 0.1 # Short sleep time to prevent busy waiting
    end
  end

  def ajax_requests_finished?
    # This method MUST NOT be interrupted. Hence, Timeout.timeout is not used here.
    # Otherwise, Selenium and the browser driver might crash, preventing further tests from running.
    page.evaluate_script('jQuery.active').zero?
  end
end

RSpec.configure do |config|
  config.include WaitForAjax, type: :system
end
