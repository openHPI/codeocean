# frozen_string_literal: true

module ExerciseHelper
  include LtiHelper

  SETTINGS = CodeOcean::Config.new(:code_ocean)
  EVENT_SETTINGS = SETTINGS.read[:codeocean_events] || {}
  FLOWR_SETTINGS = SETTINGS.read[:flowr] || {}

  def embedding_parameters(exercise)
    "locale=#{I18n.locale}&token=#{exercise.token}"
  end

  def flowr_settings
    {
      enabled: FLOWR_SETTINGS.fetch(:enabled, false),
      answers_per_query: FLOWR_SETTINGS.fetch(:answers_per_query, 3),
    }
  end

  def editor_events_enabled
    EVENT_SETTINGS.fetch(:enabled, false)
  end
end
