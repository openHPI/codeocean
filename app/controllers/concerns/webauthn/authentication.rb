# frozen_string_literal: true

module Webauthn
  module Authentication
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.before_action :require_fully_authenticated_user!

      Sorcery::Controller::Config.after_login << :require_webauthn_credential_verification
      Sorcery::Controller::Config.after_remember_me << :require_webauthn_credential_verification
      Sorcery::Controller::Config.after_logout << :destroy_webauthn_cookie
    end

    module InstanceMethods
      # Verify user presence and ensure the sign-in process finished.
      # If configured previously, the user must have completed the WebAuthn authentication.
      # This method is intended to be used as a before_action.
      def require_fully_authenticated_user!
        require_partially_authenticated_user!
        if current_user.webauthn_configured?
          _require_webauthn_credential_authentication
          refresh_webauthn_cookie
        else
          current_user.store_authentication_result(true)
        end
      end

      # Verify that a user is signed in (and that we have a current_user).
      # This method does not check for the completion of the WebAuthn authentication.
      # This method is intended to be used as a before_action.
      def require_partially_authenticated_user!
        raise Pundit::NotAuthorizedError unless current_user
      end

      # This method is called after the first login step when *not using a password*.
      # For example, it could be called when signing in using LTI or an authentication token.
      # Password-based logins are handled by Sorcery, and will call `require_webauthn_credential_verification`.
      def authenticate(user)
        _sign_in_as(user)
        return _finalize_login(user) if user.fully_authenticated?

        redirect_to new_webauthn_credential_authentication_path
        user
      end

      # This method is called after the WebAuthn authentication is completed.
      # It is intended to be used in the WebAuthnCredentialAuthentication controller.
      def authenticate_webauthn_for(webauthn_credential)
        _store_in_webauthn_cookie(webauthn_credential)
        _finalize_login(webauthn_credential.user)
      end

      # This method can be used to redirect users who are already fully authenticated.
      # It is intended to be used as a before_action in the WebAuthnCredentialAuthentication controller.
      def redirect_fully_authenticated_users
        if session[:return_to_url].blank? && session[:return_to_url_notice].blank? && request.referer.blank?
          session[:return_to_url_alert] = t('application.not_authorized')
        end
        _finalize_login(current_user) if _webauthn_credential_authentication_completed?(current_user)
      end

      private

      ######################################################
      # Sorcery Hooks
      ######################################################

      # If the user has configured WebAuthn, require the WebAuthn authentication after login.
      def require_webauthn_credential_verification(user, _credential = nil)
        return unless user.webauthn_configured?

        _require_webauthn_credential_authentication user
      end

      # Refresh the WebAuthn cookie on each request if the user has completed the WebAuthn authentication.
      def refresh_webauthn_cookie
        return unless current_user
        return unless _webauthn_credential_authentication_completed?(current_user)

        Webauthn::Cookie.new(request).refresh
      end

      # Remove the WebAuthn cookie after the user logs out.
      def destroy_webauthn_cookie(_user = nil)
        webauthn_cookie = Webauthn::Cookie.new(request)
        webauthn_cookie.clear
      end

      ######################################################
      # Internal Methods, use with caution!
      ######################################################

      # Redirect to the WebAuthn authentication page if the user has not completed the WebAuthn authentication.
      def _require_webauthn_credential_authentication(user = current_user)
        redirect_to new_webauthn_credential_authentication_path unless _webauthn_credential_authentication_completed?(user)
      end

      # Finish the login process and redirect the user to the return_to_url.
      # This method is called after the second login step, i.e., after verifying the WebAuthn credential.
      # If no WebAuthn credential is required, the method might be called directly after the first login step.
      def _finalize_login(user)
        flash = {notice: session.delete(:return_to_url_notice), alert: session.delete(:return_to_url_alert)}.compact_blank
        sorcery_redirect_back_or_to(:root, flash) unless session[:return_to_url] == request.fullpath
        user.store_authentication_result(true)
      end

      # Sign in the user (by setting the session) and store the authentication result.
      def _sign_in_as(user)
        if user.is_a? InternalUser
          # Sorcery Login only works for InternalUsers
          auto_login(user)
        else
          # All external users are logged in "manually"
          session[:external_user_id] = user.id
        end

        _store_authentication_result(user)
      end

      def _store_authentication_result(user)
        return unless user
        return user if user.fully_authenticated?

        if user.webauthn_configured?
          # The user is fully authenticated if the WebAuthn authentication completed
          user.store_authentication_result(_webauthn_credential_authentication_completed?(user))
        else
          # No additional authentication required
          user.store_authentication_result(true)
        end
      end

      # Store the WebAuthn credential and user in a dedicated cookie to indicate full authentication.
      # A dedicated cookie is beneficial for LTI-based logins; otherwise, a user would need to reauthenticate for each LTI launch.
      def _store_in_webauthn_cookie(webauthn_credential)
        webauthn_cookie = Webauthn::Cookie.new(request)
        webauthn_cookie.store(:webauthn_user, webauthn_credential.user.id_with_type)
        webauthn_cookie.store(:webauthn_credential, webauthn_credential.id)
      end

      # Check if the user has successfully completed the WebAuthn authentication.
      # Furthermore, memorize the result for the given user.
      def _webauthn_credential_authentication_completed?(user)
        return false unless user.webauthn_configured?
        return true if user.fully_authenticated? # Simple memorization for the current request

        webauthn_cookie = Webauthn::Cookie.new(request)
        return false unless webauthn_cookie.key?(:webauthn_user)
        return false unless webauthn_cookie.key?(:webauthn_credential)

        webauthn_credential = WebauthnCredential.find_by(id: webauthn_cookie.content[:webauthn_credential])
        return false unless webauthn_credential
        return false unless user == webauthn_credential.user
        return false unless user.id_with_type == webauthn_cookie.content[:webauthn_user]

        user.store_authentication_result(true)
        true
      end
    end
  end
end
