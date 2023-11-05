# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_contributor

    def connect
      # The order is important here, because a valid user is required to find a valid contributor.
      self.current_user = find_verified_user
      self.current_contributor = find_verified_contributor

      set_sentry_context
    end

    def disconnect
      # Any cleanup work needed when the cable connection is cut.
    end

    private

    def session
      # `session` is not available here, so that we need to use `cookies.encrypted` instead
      cookies.encrypted[Rails.application.config.session_options[:key]]&.symbolize_keys || {}
    end

    def find_verified_user
      # Finding the current_user is similar to the code used in application_controller.rb#current_user
      current_user = ExternalUser.find_by(id: session[:external_user_id]) || InternalUser.find_by(id: session[:user_id])
      current_user&.store_current_study_group_id(session[:study_group_id])
      current_user || reject_unauthorized_connection
    end

    def find_verified_contributor
      # Finding the current_contributor is similar to the code used in application_controller.rb#current_contributor
      if session[:pg_id]
        Sentry.set_extras(pg_id: session[:pg_id])
        current_user.programming_groups.find(session[:pg_id])
      else
        current_user
      end
    end

    def set_sentry_context
      return if current_user.blank?

      Sentry.set_user(
        id: current_user.id,
        type: current_user.class.name,
        consumer: current_user.consumer&.name
      )
    end
  end
end
