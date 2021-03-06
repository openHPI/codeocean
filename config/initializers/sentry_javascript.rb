# frozen_string_literal: true

class SentryJavascript
  def self.active?
    dsn.present? && %w[development test].exclude?(environment)
  end

  def self.dsn
    ENV['SENTRY_JAVASCRIPT_DSN']
  end

  def self.release
    Sentry.configuration.release
  end

  def self.environment
    Sentry.configuration.environment
  end
end
