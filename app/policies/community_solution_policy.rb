# frozen_string_literal: true

class CommunitySolutionPolicy < AdminOnlyPolicy
  def edit?
    everyone
  end

  def update?
    everyone
  end
end
