# frozen_string_literal: true

class CommunitySolutionPolicy < AdminOnlyPolicy
  def show?
    # We don't have a show action, so no one can show a CommunitySolution directly.
    no_one
  end

  def new?
    # We don't have a destroy action, so no one can create a CommunitySolution directly.
    no_one
  end

  def create?
    # We don't have a destroy action, so no one can initialize a CommunitySolution directly.
    no_one
  end

  def edit?
    everyone
  end

  def update?
    everyone
  end

  def destroy?
    # We don't have a destroy action, so no one can destroy a CommunitySolution directly.
    no_one
  end
end
