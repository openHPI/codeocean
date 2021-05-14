# frozen_string_literal: true

class TipPolicy < AdminOnlyPolicy
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
