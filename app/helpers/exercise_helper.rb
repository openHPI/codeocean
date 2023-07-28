# frozen_string_literal: true

module ExerciseHelper
  include LtiHelper

  def embedding_parameters(exercise)
    "locale=#{I18n.locale}&token=#{exercise.token}"
  end
end
