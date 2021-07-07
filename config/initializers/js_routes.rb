# frozen_string_literal: true

JsRoutes.setup do |config|
  config.documentation = false
  config.prefix = Rails.application.config.relative_url_root
  config.url_links = true
end
