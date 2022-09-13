# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

def self.cookie_prefix
  if (Rails.env.production? || Rails.env.staging?) \
    && Rails.application.config.relative_url_root == '/'
    '__Host-'
  elsif Rails.env.production? || Rails.env.staging?
    '__Secure-'
  else
    ''
  end
end

Rails.application.config.session_store :cookie_store,
  key: "#{cookie_prefix}CodeOcean-Session",
  expire_after: 1.month,
  secure: Rails.env.production? || Rails.env.staging?,
  path: Rails.application.config.relative_url_root,
  # Signing in through LTI won't work with `SameSite=Strict`
  # as the cookie is not sent when accessing the `implement` route
  # following the LTI launch initiated by the LMS as a third party.
  same_site: :lax
