# frozen_string_literal: true

require_relative 'sentry'

class SentryCsp
  def self.active?
    dsn.present? && %w[development test].exclude?(environment)
  end

  def self.report_url
    parsed_url = URI.parse dsn

    # Add additional variables to the query string
    query_params = CGI.parse(parsed_url.query || '')
    query_params[:sentry_release] = release if release
    query_params[:sentry_environment] = environment if environment

    # Add the query string back to the URL
    parsed_url.query = URI.encode_www_form(query_params)

    # Return the full URL
    parsed_url.to_s
  end

  class << self
    private

    def dsn
      ENV.fetch('SENTRY_CSP_REPORT_URL', nil)
    end

    def release
      Sentry.configuration.release
    end

    def environment
      Sentry.configuration.environment
    end
  end
end
