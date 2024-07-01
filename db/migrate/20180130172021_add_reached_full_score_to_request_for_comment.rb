# frozen_string_literal: true

class AddReachedFullScoreToRequestForComment < ActiveRecord::Migration[4.2]
  class RequestForComment < ApplicationRecord
    belongs_to :submission, optional: true
    belongs_to :user, optional: true
  end

  class Submission < ApplicationRecord
    belongs_to :exercise
    belongs_to :user, polymorphic: true
  end

  class Exercise < ApplicationRecord
    has_many :files, as: :context, class_name: 'CodeOcean::File'
    has_many :submissions

    def solved_by?(user)
      maximum_score(user).to_i == maximum_score.to_i
    end

    def maximum_score(user)
      if user
        submissions
          .where(user:, cause: %w[submit assess])
          .where.not(score: nil)
          .order(score: :desc)
          .first&.score || 0
      else
        @maximum_score ||= if files.loaded?
                             files.filter(&:teacher_defined_assessment?).pluck(:weight).sum
                           else
                             files.teacher_defined_assessments.sum(:weight)
                           end
      end
    end
  end

  class CodeOcean::File < ApplicationRecord
    belongs_to :context, polymorphic: true
    scope :teacher_defined_assessments, -> { where(role: %w[teacher_defined_test teacher_defined_linter]) }

    ROLES = %w[regular_file main_file reference_implementation executable_file teacher_defined_test user_defined_file
               user_defined_test teacher_defined_linter].freeze

    def teacher_defined_assessment?
      teacher_defined_test? || teacher_defined_linter?
    end

    ROLES.each do |role|
      define_method(:"#{role}?") { self.role == role }
    end
  end

  def up
    add_column :request_for_comments, :full_score_reached, :boolean, default: false
    RequestForComment.find_each do |rfc|
      if rfc.submission.present? && rfc.submission.exercise.solved_by?(rfc.user)
        rfc.full_score_reached = true
        rfc.save
      end
    end
  end

  def down
    remove_column :request_for_comments, :full_score_reached
  end
end
