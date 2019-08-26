# frozen_string_literal: true

class CodeharborLinkPolicy < ApplicationPolicy
  def index?
    teacher?
  end

  def create?
    teacher?
  end

  def show?
    teacher?
  end

  def edit?
    teacher?
  end

  def destroy?
    teacher?
  end

  def new?
    teacher?
  end

  def update?
    teacher?
  end
end
