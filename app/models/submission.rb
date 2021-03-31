# frozen_string_literal: true

class Submission < ApplicationRecord
  include Context
  include Creation
  include ActionCableHelper
  include SubmissionScoring

  require 'concurrent/future'

  CAUSES = %w[assess download file render run save submit test autosave requestComments remoteAssess
              remoteSubmit].freeze
  FILENAME_URL_PLACEHOLDER = '{filename}'
  MAX_COMMENTS_ON_RECOMMENDED_RFC = 5
  OLDEST_RFC_TO_SHOW = 6.months

  belongs_to :exercise
  belongs_to :study_group, optional: true

  has_many :testruns
  has_many :structured_errors
  has_many :comments, through: :files

  belongs_to :external_users, lambda {
                                where(submissions: {user_type: 'ExternalUser'}).includes(:submissions)
                              }, foreign_key: :user_id, class_name: 'ExternalUser', optional: true
  belongs_to :internal_users, lambda {
                                where(submissions: {user_type: 'InternalUser'}).includes(:submissions)
                              }, foreign_key: :user_id, class_name: 'InternalUser', optional: true

  delegate :execution_environment, to: :exercise

  scope :final, -> { where(cause: %w[submit remoteSubmit]) }
  scope :intermediate, -> { where.not(cause: 'submit') }

  scope :before_deadline, lambda {
                            joins(:exercise).where('submissions.updated_at <= exercises.submission_deadline OR exercises.submission_deadline IS NULL')
                          }
  scope :within_grace_period, lambda {
                                joins(:exercise).where('(submissions.updated_at > exercises.submission_deadline) AND (submissions.updated_at <= exercises.late_submission_deadline OR exercises.late_submission_deadline IS NULL)')
                              }
  scope :after_late_deadline, lambda {
                                joins(:exercise).where('submissions.updated_at > exercises.late_submission_deadline')
                              }

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
    collect_files.detect {|file| file.filepath == file_path }
  end

  def normalized_score
    ::NewRelic::Agent.add_custom_attributes({unnormalized_score: score})
    if !score.nil? && !exercise.maximum_score.nil? && exercise.maximum_score.positive?
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
    RequestForComment.unsolved.find_by(exercise_id: exercise, user_id: user_id)
  end

  def unsolved_rfc
    RequestForComment.unsolved.where(exercise_id: exercise).where.not(question: nil).where(created_at: OLDEST_RFC_TO_SHOW.ago..Time.current).order('RANDOM()').find do |rfc_element|
      ((rfc_element.comments_count < MAX_COMMENTS_ON_RECOMMENDED_RFC) && !rfc_element.question.empty?)
    end
  end

  def calculate_score
    score = nil
    prepared_container do |container|
      scores = collect_files.select(&:teacher_defined_assessment?).map do |file|
        score_command = command_for execution_environment.test_command, file.name_with_extension
        stdout = ""
        stderr = ""
        exit_code = 0
        container.execute_interactively(score_command) do |container, socket|
          socket.on :stderr do
            |data| stderr << data
          end
          socket.on :stdout do
            |data| stdout << data
          end
          socket.on :close do |_exit_code|
            exit_code = _exit_code
            EventMachine.stop_event_loop
          end
        end
        output = {
          file_role: file.role,
          waiting_for_container_time: 1.second, # TODO
          container_execution_time: 1.second, # TODO
          status: (exit_code == 0) ? :ok : :failed,
          stdout: stdout,
          stderr: stderr,
        }
        test_result(output, file)
      end
      score = score_submission(scores)
    end
    JSON.dump(score)
  end

  def run(file, &block)
    run_command = command_for execution_environment.run_command, file
    prepared_container do |container|
      container.execute_interactively(run_command, &block)
    end
  end

  private

  def prepared_container
    request_time = Time.now
    container = Container.new(execution_environment, execution_environment.permitted_execution_time)
    container.copy_submission_files self
    container_time = Time.now
    waiting_for_container_time = Time.now - request_time
    yield(container) if block_given?
    execution_time = Time.now - container_time
    container.destroy
  end

  def command_for(template, file)
    filepath = collect_files.find { |f| f.name_with_extension == file }.filepath
    template % command_substitutions(filepath)
  end

  def command_substitutions(filename)
    {
      class_name: File.basename(filename, File.extname(filename)).camelize,
      filename: filename,
      module_name: File.basename(filename, File.extname(filename)).underscore
    }
  end
end
