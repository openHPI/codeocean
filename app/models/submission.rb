class Submission < ApplicationRecord
  include Context
  include Creation
  include ActionCableHelper

  CAUSES = %w(assess download file render run save submit test autosave requestComments remoteAssess remoteSubmit)
  FILENAME_URL_PLACEHOLDER = '{filename}'
  MAX_COMMENTS_ON_RECOMMENDED_RFC = 5
  OLDEST_RFC_TO_SHOW = 6.months

  belongs_to :exercise
  belongs_to :study_group, optional: true

  has_many :testruns
  has_many :structured_errors
  has_many :comments, through: :files

  belongs_to :external_users, -> { where(submissions: {user_type: 'ExternalUser'}).includes(:submissions) }, foreign_key: :user_id, class_name: 'ExternalUser', optional: true
  belongs_to :internal_users, -> { where(submissions: {user_type: 'InternalUser'}).includes(:submissions) }, foreign_key: :user_id, class_name: 'InternalUser', optional: true

  delegate :execution_environment, to: :exercise

  scope :final, -> { where(cause: 'submit') }
  scope :intermediate, -> { where.not(cause: 'submit') }

  scope :before_deadline, -> { joins(:exercise).where('submissions.updated_at <= exercises.submission_deadline OR exercises.submission_deadline IS NULL') }
  scope :within_grace_period, -> { joins(:exercise).where('(submissions.updated_at > exercises.submission_deadline) AND (submissions.updated_at <= exercises.late_submission_deadline OR exercises.late_submission_deadline IS NULL)') }
  scope :after_late_deadline, -> { joins(:exercise).where('submissions.updated_at > exercises.late_submission_deadline') }

  scope :latest, -> { order(updated_at: :desc).first }

  scope :in_study_group_of, ->(user) { where(study_group_id: user.study_groups) unless user.admin? }

  validates :cause, inclusion: {in: CAUSES}
  validates :exercise_id, presence: true

  # after_save :trigger_working_times_action_cable


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

  def file_by_name(file_path)
    # expects the full file path incl. file extension
    # Caution: There must be no unnecessary path prefix included.
    # Use `file.ext` rather than `./file.ext`
    collect_files.detect { |file| file.filepath == file_path }
  end

  def normalized_score
    ::NewRelic::Agent.add_custom_attributes({unnormalized_score: score})
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

  def before_deadline?
    if exercise.submission_deadline.present?
      updated_at <= exercise.submission_deadline
    else
      false
    end
  end

  def within_grace_period?
    if exercise.submission_deadline.present? && exercise.late_submission_deadline.present?
      updated_at > exercise.submission_deadline && updated_at <= exercise.late_submission_deadline
    else
      false
    end
  end

  def after_late_deadline?
    if exercise.late_submission_deadline.present?
      updated_at > exercise.late_submission_deadline
    elsif exercise.submission_deadline.present?
      updated_at > exercise.submission_deadline
    else
      false
    end
  end

  def redirect_to_feedback?
    # Redirect 10% of users to the exercise feedback page. Ensure, that always the same
    # users get redirected per exercise and different users for different exercises. If
    # desired, the number of feedbacks can be limited with exercise.needs_more_feedback?(submission)
    (user_id + exercise.created_at.to_i) % 10 == 1
  end

  def own_unsolved_rfc
    RequestForComment.unsolved.where(exercise_id: exercise, user_id: user_id).first
  end

  def unsolved_rfc
    RequestForComment.unsolved.where(exercise_id: exercise).where.not(question: nil).where(created_at: OLDEST_RFC_TO_SHOW.ago..Time.current).order("RANDOM()").find { |rfc_element| ((rfc_element.comments_count < MAX_COMMENTS_ON_RECOMMENDED_RFC) && (!rfc_element.question.empty?)) }
  end
end
