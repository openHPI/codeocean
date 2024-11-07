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
    return true if admin? || author? || author_in_programming_group?
    # Performance optimization: If this submission is within the CausesScope, we can skip the expensive DeadlineScope
    return true if teacher_in_study_group? && CausesScope.new(@user, @record).resolve.include?(@record.cause)

    teacher_in_study_group? && DeadlineScope.new(@user, Submission).resolve.exists?(@record.id)
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
        %w[submit remoteSubmit requestComments]
      else
        []
      end
    end
  end

  class DeadlineScope < Scope
    def resolve
      resolved_scope = super
      return resolved_scope unless @user.teacher?

      latest_before_deadline = latest_submissions_assessed.before_deadline.arel
      latest_within_grace_period = latest_submissions_assessed.within_grace_period.arel
      latest_after_late_deadline = latest_submissions_assessed.after_late_deadline.arel
      highest_before_deadline = latest_submissions_assessed(highest_scored: true).before_deadline.arel
      highest_within_grace_period = latest_submissions_assessed(highest_scored: true).within_grace_period.arel
      highest_after_late_deadline = latest_submissions_assessed(highest_scored: true).after_late_deadline.arel

      # Yes, we construct a huge union of seven relations: all three deadlines, all three highest scores and the resolved scope
      all_unions = construct_union(
        latest_before_deadline,
        latest_within_grace_period,
        latest_after_late_deadline,
        highest_before_deadline,
        highest_within_grace_period,
        highest_after_late_deadline,
        # Dirty hack, since resolved_scope.arel will loose the bindings, and replace them with $1, $2, ...
        Arel.sql(resolved_scope.to_sql)
      )

      # Convert the union to a relation
      Submission.from(all_unions.as(Submission.arel_table.name))
    end

    private

    # This method is used to get the latest submission that was assessed or remote assessed.
    # By default, it will simply return the one with the last time stamp per exercise and contributor.
    # However, with the optional parameter, the highest scored submission that was scored the latest will be returned.
    def latest_submissions_assessed(highest_scored: false)
      submission_table = Submission.arel_table

      desired_table_order = [
        submission_table[:exercise_id],
        submission_table[:contributor_type],
        submission_table[:contributor_id],
        highest_scored ? submission_table[:score].desc.nulls_last : nil,
        submission_table[:created_at].desc,
      ].compact

      Submission.from(
        submission_table.project(
          Arel.sql('DISTINCT ON (submissions.exercise_id, submissions.contributor_type, submissions.contributor_id) submissions.*')
        )
        .order(*desired_table_order)
        .where(submission_table[:cause].in(%w[assess remoteAssess]))
        .where(submission_table[:study_group_id].in(@user.study_group_ids_as_teacher))
        .as(submission_table.name)
      )
    end

    def construct_union(*args)
      return nil if args.empty?
      return args.first if args.size == 1

      args.reduce do |union, arg|
        Arel::Nodes::Union.new(union, arg)
      end
    end
  end
end
