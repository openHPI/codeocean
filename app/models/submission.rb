class Submission < ApplicationRecord
  include Context
  include Creation
  include ActionCableHelper

  CAUSES = %w(assess download file render run save submit test autosave requestComments remoteAssess)
  FILENAME_URL_PLACEHOLDER = '{filename}'
  MAX_COMMENTS_ON_RECOMMENDED_RFC = 5
  OLDEST_RFC_TO_SHOW = 6.months

  belongs_to :exercise
  belongs_to :study_group, optional: true

  has_many :testruns
  has_many :structured_errors
  has_many :comments, through: :files

  delegate :execution_environment, to: :exercise

  scope :final, -> { where(cause: 'submit') }
  scope :intermediate, -> { where.not(cause: 'submit') }

  validates :cause, inclusion: {in: CAUSES}
  validates :exercise_id, presence: true

  after_save :trigger_working_times_action_cable


  def build_files_hash(files, attribute)
    files.map(&attribute.to_proc).zip(files).to_h
  end
  private :build_files_hash

  def collect_files
    ancestors = build_files_hash(exercise.files.includes(:file_type), :id)
    descendants = build_files_hash(files.includes(:file_type), :file_id)
    ancestors.merge(descendants).values
  end

  def main_file
    collect_files.detect(&:main_file?)
  end

  def normalized_score
    ::NewRelic::Agent.add_custom_attributes({ unnormalized_score: score })
    if !score.nil? && !exercise.maximum_score.nil? && (exercise.maximum_score > 0)
      score / exercise.maximum_score
    else
      0
    end
  end

  def percentage
    (normalized_score * 100).round
  end

  def siblings
    user.submissions.where(exercise_id: exercise_id)
  end

  def to_s
    Submission.model_name.human
  end

  def redirect_to_feedback?
    ((user_id + exercise.created_at.to_i) % 10 == 1) && exercise.needs_more_feedback?
  end

  def own_unsolved_rfc
    RequestForComment.unsolved.where(exercise_id: exercise, user_id: user_id).first
  end

  def unsolved_rfc
    RequestForComment.unsolved.where(exercise_id: exercise).where.not(question: nil).where(created_at: OLDEST_RFC_TO_SHOW.ago..Time.current).order("RANDOM()").find { | rfc_element |( (rfc_element.comments_count < MAX_COMMENTS_ON_RECOMMENDED_RFC) && (!rfc_element.question.empty?)) }
  end
end
