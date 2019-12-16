class CodeharborLinkPolicy < ApplicationPolicy
  def index?
    false
  end

  def show?
    false
  end

  def new?
    teacher? || admin?
  end

  def create?
    teacher? || admin?
  end

  def edit?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    @record.reload.user == @user
  end
end
