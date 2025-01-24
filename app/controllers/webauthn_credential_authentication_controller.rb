# frozen_string_literal: true

class WebauthnCredentialAuthenticationController < ApplicationController
  skip_before_action :require_fully_authenticated_user!
  before_action :require_partially_authenticated_user!
  before_action :deny_access_for_users_without_webauthn_credentials
  before_action :redirect_fully_authenticated_users
  before_action :authorize!

  def new
    @webauthn_get_options = personalized_options
    session[:current_challenge] = @webauthn_get_options.challenge
  end

  def create
    raise WebAuthn::Error.new(t('.missing_challenge')) unless session[:current_challenge]
    raise WebAuthn::Error.new(t('.invalid_param')) unless credential_param.is_a?(Hash) && credential_param.key?('rawId')

    webauthn_credential = WebAuthn::Credential.from_get(credential_param)
    credential = current_user.webauthn_credentials.find_by(external_id: webauthn_credential.id)
    raise WebAuthn::Error.new(t('.credential_not_found')) unless credential

    webauthn_credential.verify(
      session.delete(:current_challenge),
      public_key: credential.public_key,
      sign_count: credential.sign_count,
      user_presence: true,
      user_verification: true
    )

    credential.assign_attributes(
      sign_count: webauthn_credential.sign_count,
      last_used_at: Time.zone.now
    )
    credential.save(touch: false)

    authenticate_webauthn_for(credential)
  rescue WebAuthn::Error => e
    redirect_to new_webauthn_credential_authentication_path, danger: t('.failed', error: e.message)
  end

  private

  def personalized_options
    WebAuthn::Credential.options_for_get(
      allow_credentials:,
      user_verification: :required
    )
  end

  def allow_credentials
    current_user.webauthn_credentials.map do |cred|
      {id: cred.external_id, type: WebAuthn::TYPE_PUBLIC_KEY, transports: cred.transports}
    end
  end

  def authorize!
    authorize current_user, policy_class: WebauthnCredentialAuthenticationPolicy
  end

  def deny_access_for_users_without_webauthn_credentials
    raise Pundit::NotAuthorizedError unless current_user.webauthn_configured?
  end

  def credential_param
    return @credential_param if defined? @credential_param

    credential_param = params.expect(webauthn_credential: [:credential])[:credential]
    @credential_param = JSON.parse(credential_param.to_s)
  rescue JSON::ParserError
    @credential_param = {}
  end
end
