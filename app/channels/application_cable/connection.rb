# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    def disconnect
      # Any cleanup work needed when the cable connection is cut.
    end

    private

    def session
      # `session` is not available here, so that we need to use `cookies.encrypted` instead
      cookies.encrypted[Rails.application.config.session_options[:key]].symbolize_keys
    end

    def find_verified_user
      # Finding the current_user is similar to the code used in application_controller.rb#current_user
      current_user = ExternalUser.find_by(id: session[:external_user_id]) || InternalUser.find_by(id: session[:user_id])
      current_user || reject_unauthorized_connection
    end
  end
end
