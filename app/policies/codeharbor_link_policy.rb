# frozen_string_literal: true

class CodeharborLinkPolicy < ApplicationPolicy
  def index?
    false
  end

  def show?
    false
  end

  def new?
    teacher?
  end

  def create?
    teacher?
  end

  def edit?
    teacher?
  end

  def update?
    teacher?
  end

  def destroy?
    teacher?
  end
end
