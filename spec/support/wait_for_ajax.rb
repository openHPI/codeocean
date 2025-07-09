# frozen_string_literal: true

module WaitForAjax
  def wait_for_ajax
    start_time = Time.current
    timeout = Capybara.default_max_wait_time

    loop do
      sleep 0.1 # Short sleep time to prevent busy waiting
      break if (ajax_requests_finished? && turbo_finished?) || (Time.current - start_time) > timeout
    end
  end

  def ajax_requests_finished?
    # This method MUST NOT be interrupted. Hence, Timeout.timeout is not used here.
    # Otherwise, Selenium and the browser driver might crash, preventing further tests from running.
    page.evaluate_script('jQuery.active').zero?
  end

  def turbo_finished?
    # Check if Turbo is finished by looking for the absence of the progress bar.
    if has_css?('.turbo-progress-bar', visible: true, wait: 0.1.seconds)
      has_no_css?('.turbo-progress-bar')
    end
  end
end

RSpec.configure do |config|
  config.include WaitForAjax, type: :system
end
