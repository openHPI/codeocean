# frozen_string_literal: true

class AdminOnlyPolicy < ApplicationPolicy
  %i[create? destroy? edit? index? new? show? update?].each do |action|
    define_method(action) { admin? }
  end
end
