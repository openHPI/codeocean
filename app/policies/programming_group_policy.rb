# frozen_string_literal: true

class ProgrammingGroupPolicy < ApplicationPolicy
  def new?
    everyone
  end

  def create?
    everyone
  end
end
