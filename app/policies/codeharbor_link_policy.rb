# frozen_string_literal: true

class CodeharborLinkPolicy < ApplicationPolicy
  CODEHARBOR_CONFIG = CodeOcean::Config.new(:code_ocean).read[:codeharbor]

  def index?
    false
  end

  def show?
    false
  end

  def new?
    enabled? && (teacher? || admin?)
  end

  def create?
    enabled? && (teacher? || admin?)
  end

  def edit?
    enabled? && owner?
  end

  def update?
    enabled? && owner?
  end

  def destroy?
    enabled? && owner?
  end

  def enabled?
    CODEHARBOR_CONFIG[:enabled]
  end

  private

  def owner?
    @record.reload.user == @user
  end
end
