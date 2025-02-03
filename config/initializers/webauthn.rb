# frozen_string_literal: true

Rails.application.config.after_routes_loaded do
  WebAuthn.configure do |config|
    # This value needs to match `window.location.origin` evaluated by
    # the User Agent during registration and authentication ceremonies.
    if Rails.env.test?
      # The test environment requires `ActionDispatch::Integration::Session::DEFAULT_HOST`
      # or `www.example.com` as the default host for the authentication to work.
      Rails.application.routes.default_url_options[:host] = ActionDispatch::Integration::Session::DEFAULT_HOST
    else
      # The default host is only used when no request-provided origin is available.
      Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
    end
    # If this origin doesn't match the request origin, the request will fail.
    # In that case, a `WebAuthn::OriginVerificationError` will be raised.
    config.origin = Rails.application.routes.url_helpers.root_url.chomp('/')

    # Relying Party name for display purposes
    config.rp_name = ApplicationHelper::APPLICATION_NAME

    # Optionally configure a client timeout hint, in milliseconds.
    # This hint specifies how long the browser should wait for any
    # interaction with the user.
    # This hint may be overridden by the browser.
    # https://www.w3.org/TR/webauthn/#dom-publickeycredentialcreationoptions-timeout
    # config.credential_options_timeout = 120_000

    # You can optionally specify a different Relying Party ID
    # (https://www.w3.org/TR/webauthn/#relying-party-identifier)
    # if it differs from the default one.
    #
    # In this case the default would be "auth.example.com", but you can set it to
    # the suffix "example.com"
    #
    # config.rp_id = "example.com"

    # Configure preferred binary-to-text encoding scheme. This should match the encoding scheme
    # used in your client-side (user agent) code before sending the credential to the server.
    # Supported values: `:base64url` (default), `:base64` or `false` to disable all encoding.
    #
    # config.encoding = :base64url

    # Possible values: "ES256", "ES384", "ES512", "PS256", "PS384", "PS512", "RS256", "RS384", "RS512", "RS1"
    # Default: ["ES256", "PS256", "RS256"]
    #
    # config.algorithms << "ES384"
  end
end
