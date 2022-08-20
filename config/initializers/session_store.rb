# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: '_code_ocean_session',
  expire_after: 1.month,
  secure: Rails.env.production? || Rails.env.staging?,
  path: Rails.application.config.relative_url_root
