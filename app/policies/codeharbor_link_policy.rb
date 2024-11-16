# frozen_string_literal: true

class CodeharborLinkPolicy < ApplicationPolicy
  CODEHARBOR_CONFIG = CodeOcean::Config.new(:code_ocean).read[:codeharbor]

  %i[index? show?].each do |action|
    define_method(action) { no_one }
  end

  %i[new? create?].each do |action|
    define_method(action) { enabled? && (admin? || teacher?) && (@user.admin? || @user.teacher?) }
  end

  %i[destroy? update? edit?].each do |action|
    define_method(action) { enabled? && (admin? || owner?) }
  end

  def enabled?
    CODEHARBOR_CONFIG[:enabled]
  end

  private

  def owner?
    @record.user == @user
  end
end
