# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy
  def create?
    everyone
  end

  # insights? is used in the flowr_controller.rb as we use it to authorize the user for a submission
  %i[download? download_file? run? score? statistics? stop? test? insights? finalize?].each do |action|
    define_method(action) { admin? || author? || author_in_programming_group? }
  end

  # download_submission_file? is used in the live_streams_controller.rb
  %i[render_file? download_submission_file?].each do |action|
    define_method(action) do
      # The AuthenticatedUrlHelper will check for more details, but we cannot determine a specific user
      everyone
    end
  end

  def index?
    admin? || teacher?
  end

  def show?
    admin? || author? || author_in_programming_group? || teacher_in_study_group?
  end

  def show_study_group?
    admin? || teacher_in_study_group?
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.where(study_group_id: @user.study_group_ids_as_teacher, cause: CausesScope.new(@user, Submission).resolve)
      else
        @scope.none
      end
    end
  end

  class CausesScope < Scope
    def resolve
      if @user.admin?
        Submission::CAUSES
      elsif @user.teacher?
        %w[submit remoteSubmit]
      else
        []
      end
    end
  end
end
