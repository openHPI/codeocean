# frozen_string_literal: true

Rails.application.config.after_initialize do
  require 'i18n-js/listen'
  # This will only run in development.
  I18nJS.listen
end
