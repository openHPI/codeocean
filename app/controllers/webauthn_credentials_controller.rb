# frozen_string_literal: true

class WebauthnCredentialsController < ApplicationController
  include CommonBehavior

  before_action :set_user_and_authorize
  before_action :set_webauthn_credential, only: MEMBER_ACTIONS

  def show; end

  def new
    @webauthn_credential = WebauthnCredential.new(user: @user)
    authorize @webauthn_credential

    @webauthn_create_options = personalized_options
    session[:current_challenge] = @webauthn_create_options.challenge
  end

  def edit; end

  def create
    @webauthn_credential = @user.webauthn_credentials.build(
      label: webauthn_credential_params[:label]
    )

    authorize!

    raise WebAuthn::Error.new(t('.missing_challenge')) unless session[:current_challenge]
    raise WebAuthn::Error.new(t('.invalid_param')) unless credential_param.is_a?(Hash) && credential_param.key?('rawId')

    credential = WebAuthn::Credential.from_create(credential_param)
    credential.verify(session[:current_challenge], user_presence: true, user_verification: true)

    @webauthn_credential.assign_attributes(
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: credential.sign_count,
      transports: credential.response.transports
    )

    # In case something goes wrong, we want to show the user the same options again.
    @webauthn_create_options = personalized_options
    session[:current_challenge] = @webauthn_create_options.challenge

    create_and_respond(object: @webauthn_credential, path: -> { @webauthn_credential.user }) do
      session.delete(:current_challenge)
      _store_in_webauthn_cookie(@webauthn_credential) if @webauthn_credential.user == current_user
      # Don't return a specific value from this block, so that the default is used.
      nil
    end
  rescue JSON::ParserError, WebAuthn::Error => e
    flash.now[:danger] = ERB::Util.html_escape e.message
    respond_to do |format|
      @webauthn_create_options = personalized_options
      session[:current_challenge] = @webauthn_create_options.challenge

      respond_with_invalid_object(format, template: :new)
    end
  end

  def update
    update_and_respond(object: @webauthn_credential, params: {label: webauthn_credential_params[:label]}, path: [@webauthn_credential.user, @webauthn_credential])
  end

  def destroy
    destroy_and_respond(object: @webauthn_credential, path: @webauthn_credential.user)
    if @webauthn_credential.user == current_user && !@webauthn_credential.user.webauthn_configured?
      # If the last credential was deleted by the current user, we want to remove the cookie, too.
      Webauthn::Cookie.new(request).clear
    end
  end

  private

  def personalized_options
    @user.with_lock do
      if @user.webauthn_user_id.blank?
        @user.validate_password = false if @user.respond_to?(:validate_password=)
        @user.update!(webauthn_user_id: WebAuthn.generate_user_id)
      end
    end

    WebAuthn::Credential.options_for_create(
      user: {
        id: @user.webauthn_user_id,
        display_name: @user.displayname,
        name: @user.webauthn_name,
      },
      exclude_credentials:,
      authenticator_selection: {
        user_verification: :required,
      }
    )
  end

  def exclude_credentials
    @user.webauthn_credentials.map do |cred|
      {id: cred.external_id, type: WebAuthn::TYPE_PUBLIC_KEY, transports: cred.transports}
    end
  end

  def authorize!
    raise Pundit::NotAuthorizedError if @webauthn_credential.present? && @user.present? && @webauthn_credential.user != @user

    authorize(@webauthn_credential)
  end

  def set_user_and_authorize
    if params[:external_user_id]
      @user = ExternalUser.find(params[:external_user_id])
    else
      @user = InternalUser.find(params[:internal_user_id])
    end
    params[:user_id] = @user.id_with_type # for the breadcrumbs
    authorize(@user, :register_webauthn_credential?)
  end

  def set_webauthn_credential
    @webauthn_credential = WebauthnCredential.find(params[:id])
    authorize!
  end

  def webauthn_credential_params
    params.expect(webauthn_credential: %i[credential label])
  end

  def credential_param
    return @credential_param if defined? @credential_param

    credential_param = webauthn_credential_params[:credential]
    @credential_param = JSON.parse(credential_param.to_s)
  rescue JSON::ParserError
    @credential_param = {}
  end
end
