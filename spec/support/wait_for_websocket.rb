# frozen_string_literal: true

module WaitForWebsocket
  def wait_for_websocket
    start_time = Time.current
    timeout = Capybara.default_max_wait_time

    loop do
      sleep 0.1 # Short sleep time to prevent busy waiting
      break if websocket_finished? || (Time.current - start_time) > timeout
    end
  end

  def websocket_finished?
    # This method MUST NOT be interrupted. Hence, Timeout.timeout is not used here.
    # Otherwise, Selenium and the browser driver might crash, preventing further tests from running.
    page.evaluate_script('CodeOceanEditorWebsocket?.websocket?.getReadyState() === WebSocket.CLOSED').present?
  end
end

RSpec.configure do |config|
  config.include WaitForWebsocket, type: :system
end
