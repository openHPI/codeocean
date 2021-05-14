# frozen_string_literal: true

class AdminOrAuthorPolicy < ApplicationPolicy
  %i[create? index? new?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  %i[destroy? edit? show? update?].each do |action|
    define_method(action) { admin? || author? }
  end
end
