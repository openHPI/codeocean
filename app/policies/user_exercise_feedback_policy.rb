# frozen_string_literal: true

class UserExerciseFeedbackPolicy < AdminOrAuthorPolicy
  def create?
    everyone
  end

  def new?
    everyone
  end
end
