# frozen_string_literal: true

module I18nHelper
  include HttpAcceptLanguage::EasyAccess

  def sanitized_lti_locale_param
    sanitize_locale(params[:custom_locale])
  end

  def sanitized_locale_param
    sanitize_locale(params[:locale])
  end

  def sanitized_session_locale
    sanitize_locale(session[:locale])
  end

  def choose_locale
    sanitized_lti_locale_param ||
      sanitized_locale_param ||
      sanitized_session_locale ||
      http_accept_language.compatible_language_from(I18n.available_locales) ||
      I18n.default_locale
  end

  def switch_locale(&)
    locale = choose_locale
    session[:locale] = locale
    Sentry.set_extras(locale:)
    I18n.with_locale(locale, &)
  end

  # Sanitize given locale.
  #
  # Return `nil` if the locale is blank or not available.
  #
  def sanitize_locale(locale)
    return if locale.blank?

    locale = locale.downcase.to_sym
    return unless I18n.available_locales.include?(locale)

    locale
  end
end
