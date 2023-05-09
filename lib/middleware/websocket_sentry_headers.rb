# frozen_string_literal: true

module Middleware
  class WebSocketSentryHeaders
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      extract_sentry_parameters(request) if websocket_upgrade?(request)
      @app.call(env)
    end

    private

    def websocket_upgrade?(request)
      request.has_header?('HTTP_SEC_WEBSOCKET_VERSION')
    end

    def extract_sentry_parameters(request)
      %w[HTTP_SENTRY_TRACE HTTP_BAGGAGE].each do |param|
        request.add_header(param, request.delete_param(param))
      end
    end
  end
end
