# frozen_string_literal: true

class UserExerciseFeedbackPolicy < AdminOrAuthorPolicy
  def create?
    everyone
  end

  def new?
    everyone
  end

  def show?
    # We don't have a show action, so no one can show a UserExerciseFeedback directly.
    no_one
  end
end
