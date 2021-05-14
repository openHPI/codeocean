# frozen_string_literal: true

class StudyGroupPolicy < AdminOnlyPolicy
  def index?
    admin? || teacher?
  end

  %i[show? destroy? edit? update? stream_la?].each do |action|
    define_method(action) { admin? || @user.teacher? && @record.present? && @user.study_groups.exists?(@record.id) }
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(:study_group_memberships).where('user_id = ? AND user_type = ?', @user.id, @user.class.name)
      else
        @scope.none
      end
    end
  end
end
