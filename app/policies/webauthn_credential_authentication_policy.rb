# frozen_string_literal: true

class WebauthnCredentialAuthenticationPolicy < ApplicationPolicy
  %i[create? new?].each do |action|
    define_method(action) { webauthn_credentials? }
  end

  private

  def webauthn_credentials?
    @record.webauthn_credentials.any?
  end
end
