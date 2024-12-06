# frozen_string_literal: true

class InternalUserPolicy < AdminOnlyPolicy
  def destroy?
    admin? && !@record.admin?
  end

  def index?
    admin? || teacher?
  end

  def show?
    admin? || @record == @user || teacher_in_study_group?
  end

  %i[change_codeharbor_link? change_password?].each do |action|
    define_method(action) { admin? || @record == @user }
  end

  def register_webauthn_credential?
    admin? || (@record == @user && Pundit.policy(@user, WebauthnCredential).new?)
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(:study_group_memberships)
          .where(study_group_memberships: {
            study_group_id: @user.study_group_ids_as_teacher,
          }).group(:id)
      else
        @scope.none
      end
    end
  end
end
