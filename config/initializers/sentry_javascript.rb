# frozen_string_literal: true

require_relative 'sentry'

class SentryJavascript
  def self.active?
    dsns.present? && %w[development test].exclude?(environment)
  end

  def self.recommended_dsn(host)
    cached_dsn(host) || matching_dsn(host) || dsns.first
  end

  def self.cached_dsn(host)
    @cached_dsn ||= {}
    @cached_dsn[host]
  end

  def self.matching_dsn(host)
    matching_dsn = dsns.find do |dsn|
      uri = URI.parse(dsn)
      uri.host&.ends_with? host
    end

    @cached_dsn[host] = matching_dsn if matching_dsn
    matching_dsn
  end

  def self.dsns
    @dsns ||= ENV.fetch('SENTRY_JAVASCRIPT_DSN', '').split(',')
  end

  def self.release
    Sentry.configuration.release
  end

  def self.environment
    Sentry.configuration.environment
  end
end
