# frozen_string_literal: true

module WaitForWebsocket
  def wait_for_websocket
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until websocket_finished?
    end
  end

  def websocket_finished?
    page.evaluate_script('CodeOceanEditorWebsocket?.websocket?.websocket?.readyState == WebSocket.CLOSED').present?
  end
end

RSpec.configure do |config|
  config.include WaitForWebsocket, type: :system
end
