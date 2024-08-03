# frozen_string_literal: true

class TipPolicy < AdminOnlyPolicy
  %i[index? show?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  class Scope < Scope
    def resolve
      if @user.admin? || @user.teacher?
        @scope.all
      else
        @scope.none
      end
    end
  end
end
