module ExerciseHelper
  def embedding_parameters(exercise)
    "locale=#{I18n.locale}&token=#{exercise.token}"
  end
end
