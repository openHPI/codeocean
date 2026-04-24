# frozen_string_literal: true

module Api
  class ApiController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :authenticate!

    def authenticate!
      authenticate_or_request_with_http_token do |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(
          token,
          ENV.fetch('INTERNAL_API_TOKEN', nil)
        )
      end
    end
  end
end
