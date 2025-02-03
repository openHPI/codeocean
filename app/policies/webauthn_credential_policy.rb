# frozen_string_literal: true

class WebauthnCredentialPolicy < ApplicationPolicy
  %i[create? new?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  %i[destroy? edit? show? update?].each do |action|
    define_method(action) { admin? || author? }
  end

  def index?
    no_one
  end

  private

  def author?
    @record.user == @user
  end
end
