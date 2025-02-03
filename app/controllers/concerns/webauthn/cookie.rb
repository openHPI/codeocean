# frozen_string_literal: true

module Webauthn
  class Cookie
    NAME = 'CodeOcean-WebAuthn'
    PREFIXED_NAME = AuthenticatedUrlHelper.cookie_name_for(NAME)

    attr_reader :request

    delegate :key?, to: :content

    def initialize(request)
      @request = request
    end

    def content
      @content ||= JSON.parse(cookies.encrypted[PREFIXED_NAME]).deep_symbolize_keys
    rescue JSON::ParserError, TypeError
      {}
    end

    def content=(value)
      @content = value
      if value.present?
        cookies.encrypted[PREFIXED_NAME] = {
          value: JSON.generate(value),
          expires: 1.month.from_now,
          secure: Rails.env.production? || Rails.env.staging?,
          httponly: true,
          path: Rails.application.config.relative_url_root,
          same_site: :lax, # Similar to the session cookie, we cannot use :strict here (due to LTI support).
        }
      else
        clear
      end
    end

    def store(key, value)
      self.content = content.merge({key => value})
    end

    def clear
      cookies.delete PREFIXED_NAME
    end

    def refresh
      return if content.blank?

      self.content = content
    end

    private

    def cookies
      request.cookie_jar
    end
  end
end
