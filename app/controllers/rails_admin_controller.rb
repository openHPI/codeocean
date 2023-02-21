# frozen_string_literal: true

class RailsAdminController < ApplicationController
  # RailsAdmin does not include translations. Therefore, we fallback to English locales
  skip_around_action :switch_locale
  # We check for permissions in the RailsAdmin config. Therefore, we skip Pundit checks here.
  skip_after_action :verify_authorized
end
