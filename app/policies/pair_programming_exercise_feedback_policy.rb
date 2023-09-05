# frozen_string_literal: true

class PairProgrammingExerciseFeedbackPolicy < AdminOnlyPolicy
  def create?
    everyone
  end

  def new?
    everyone
  end
end
