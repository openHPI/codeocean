# frozen_string_literal: true

module AuthenticatedUrlHelper
  include Pundit::Authorization

  class << self
    TOKEN_ALGORITHM = 'HS512'
    TOKEN_EXPIRATION = 10.minutes
    TOKEN_SECRET = Rails.application.secrets.secret_key_base
    TOKEN_PARAM = :token
    COOKIE_EXPIRATION = 30.seconds

    def sign(url, object)
      payload = {object_id: object.id, object_type: object.class.name, url:, exp: TOKEN_EXPIRATION.from_now.to_i}
      token = JWT.encode payload, TOKEN_SECRET, TOKEN_ALGORITHM

      add_query_parameters(url, {TOKEN_PARAM => token})
    end

    def retrieve!(klass, request, cookies = {}, force_render_host: true)
      # Don't use the default session mechanism and default cookie
      request.session_options[:skip] = true if force_render_host
      # Show errors as JSON format, if any
      request.format = :json

      # Disallow access from normal domain and show an error instead
      if force_render_host && ApplicationController::RENDER_HOST.present? && request.host != ApplicationController::RENDER_HOST
        raise Pundit::NotAuthorizedError
      end

      cookie_name = AuthenticatedUrlHelper.cookie_name_for(:render_file_token)
      begin
        object = klass.find(request.parameters[:id])
      rescue ActiveRecord::RecordNotFound
        raise Pundit::NotAuthorizedError
      end

      signed_url = request.parameters[TOKEN_PARAM].present? ? request.url : cookies[cookie_name]
      # Throws an exception if the token is not matching the object or has expired
      AuthenticatedUrlHelper.verify!(signed_url, object, klass)

      object
    end

    def verify!(url, object, klass)
      original_url, removed_parameters = remove_query_parameters(url, [TOKEN_PARAM])
      expected_payload = {object_id: object.id, object_type: klass.name, url: original_url}
      token = removed_parameters[TOKEN_PARAM]

      begin
        payload, = JWT.decode token, TOKEN_SECRET, true, algorithm: TOKEN_ALGORITHM
      rescue JWT::DecodeError
        raise Pundit::NotAuthorizedError
      end

      raise Pundit::NotAuthorizedError unless payload.symbolize_keys.except(:exp) == expected_payload
    end

    def prepare_short_living_cookie(value)
      {
        value:,
        expires: COOKIE_EXPIRATION.from_now,
        httponly: true,
        same_site: :strict,
        secure: Rails.env.production? || Rails.env.staging?,
        path: Rails.application.config.relative_url_root,
      }
    end

    def cookie_name_for(name)
      if (Rails.env.production? || Rails.env.staging?) \
        && Rails.application.config.relative_url_root == '/'
        "__Host-#{name}"
      elsif Rails.env.production? || Rails.env.staging?
        "__Secure-#{name}"
      else
        name
      end
    end

    def query_parameter
      TOKEN_PARAM
    end

    def add_query_parameters(url, parameters)
      parsed_url = URI.parse url

      # Add the given parameters to the query string
      query_params = CGI.parse(parsed_url.query || '')
      query_params.merge!(parameters)

      # Add the query string back to the URL
      parsed_url.query = URI.encode_www_form(query_params)

      # Return the full URL
      parsed_url.to_s
    rescue URI::InvalidURIError
      url
    end

    private

    def remove_query_parameters(url, parameters)
      parsed_url = URI.parse url

      # Remove the given parameters from the query string
      query_params = Rack::Utils.parse_nested_query(parsed_url.query || '')
      removed_params = query_params.extract!(*parameters.map(&:to_s))

      # Add the query string back to the URL
      parsed_url.query = URI.encode_www_form(query_params).presence

      # Return the full URL and removed parameters
      [parsed_url.to_s, removed_params.symbolize_keys]
    rescue URI::InvalidURIError
      [url, {}]
    end
  end
end
