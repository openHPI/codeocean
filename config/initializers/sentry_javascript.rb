# frozen_string_literal: true

require_relative 'sentry'

class SentryJavascript
  def self.active?
    dsn.present? && %w[development test].exclude?(environment)
  end

  def self.dsn
    ENV.fetch('SENTRY_JAVASCRIPT_DSN', nil)
  end

  def self.release
    Sentry.configuration.release
  end

  def self.environment
    Sentry.configuration.environment
  end
end
