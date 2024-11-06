# frozen_string_literal: true

class ProgrammingGroupPolicy < AdminOnlyPolicy
  def index?
    admin? || teacher?
  end

  def show?
    admin? || teacher_in_study_group?
  end

  def create?
    everyone
  end

  def new?
    everyone
  end

  def stream_sync_editor?
    # A programming group needs to exist for the user to be able to stream the synchronized editor.
    return no_one if @record.blank?

    admin? || author_in_programming_group?
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(:submissions)
          .where(submissions: {
            study_group_id: @user.study_group_ids_as_teacher,
          }).group(:id)
      else
        @scope.none
      end
    end
  end
end
