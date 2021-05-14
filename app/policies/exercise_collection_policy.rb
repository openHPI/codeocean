# frozen_string_literal: true

class ExerciseCollectionPolicy < AdminOnlyPolicy
  def statistics?
    admin?
  end
end
