# frozen_string_literal: true

class Submission < ApplicationRecord
  include Context
  include Creation
  include ActionCableHelper

  CAUSES = %w[assess download file render run save submit test autosave requestComments remoteAssess
              remoteSubmit].freeze
  FILENAME_URL_PLACEHOLDER = '{filename}'
  MAX_COMMENTS_ON_RECOMMENDED_RFC = 5
  OLDEST_RFC_TO_SHOW = 1.month

  belongs_to :exercise
  belongs_to :study_group, optional: true

  has_many :testruns
  has_many :structured_errors, dependent: :destroy
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

  attr_reader :used_execution_environment

  # after_save :trigger_working_times_action_cable

  def build_files_hash(files, attribute)
    files.map(&attribute.to_proc).zip(files).to_h
  end

  private :build_files_hash

  def collect_files
    @collect_files ||= begin
      ancestors = build_files_hash(exercise.files.includes(:file_type), :id)
      descendants = build_files_hash(files.includes(:file_type), :file_id)
      ancestors.merge(descendants).values
    end
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
    user.submissions.where(exercise_id:)
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

  def own_unsolved_rfc(user = self.user)
    Pundit.policy_scope(user, RequestForComment).unsolved.find_by(exercise_id: exercise, user_id:)
  end

  def unsolved_rfc(user = self.user)
    Pundit.policy_scope(user, RequestForComment)
      .unsolved.where.not(question: [nil, ''])
      .where(exercise_id: exercise, created_at: OLDEST_RFC_TO_SHOW.ago...)
      .left_joins(:comments)
      .having('COUNT(comments.id) < ?', MAX_COMMENTS_ON_RECOMMENDED_RFC)
      .group(:id)
      .order('RANDOM()').limit(1)
      .first
  end

  # @raise [Runner::Error] if the score could not be calculated due to a failure with the runner.
  #                        See the specific type and message for more details.
  def calculate_score
    file_scores = nil
    # If prepared_runner raises an error, no Testrun will be created.
    prepared_runner do |runner, waiting_duration|
      assessments = collect_files.select(&:teacher_defined_assessment?)
      assessment_number = assessments.size

      # We sort the test files, so that the linter checks are run first. This prevents a modification of the test file
      file_scores = assessments.sort_by {|file| file.teacher_defined_linter? ? 0 : 1 }.map.with_index(1) do |file, index|
        output = run_test_file file, runner, waiting_duration
        # If the previous execution failed and there is at least one more test, we request a new runner.
        runner, waiting_duration = swap_runner(runner) if output[:status] == :timeout && index < assessment_number
        score_file(output, file)
      end
    end
    # We sort the files again, so that the linter tests are displayed last.
    file_scores&.sort_by! {|file| file[:file_role] == 'teacher_defined_linter' ? 1 : 0 }
    combine_file_scores(file_scores)
  end

  # @raise [Runner::Error] if the code could not be run due to a failure with the runner.
  #                        See the specific type and message for more details.
  def run(file, &)
    run_command = command_for execution_environment.run_command, file.filepath
    durations = {}
    prepared_runner do |runner, waiting_duration|
      durations[:execution_duration] = runner.attach_to_execution(run_command, &)
      durations[:waiting_duration] = waiting_duration
    rescue Runner::Error => e
      e.waiting_duration = waiting_duration
      raise
    end
    durations
  end

  # @raise [Runner::Error] if the file could not be tested due to a failure with the runner.
  #                        See the specific type and message for more details.
  def test(file)
    prepared_runner do |runner, waiting_duration|
      output = run_test_file file, runner, waiting_duration
      score_file output, file
    rescue Runner::Error => e
      e.waiting_duration = waiting_duration
      raise
    end
  end

  def run_test_file(file, runner, waiting_duration)
    test_command = command_for execution_environment.test_command, file.filepath
    result = {file_role: file.role, waiting_for_container_time: waiting_duration}
    output = runner.execute_command(test_command, raise_exception: false)
    result.merge(output)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[study_group_id exercise_id cause]
  end

  private

  def prepared_runner
    request_time = Time.zone.now
    begin
      runner = Runner.for(user, exercise.execution_environment)
      files = collect_files
      files.reject!(&:reference_implementation?) if cause == 'run'
      files.reject!(&:teacher_defined_assessment?) if cause == 'run'
      Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Copying files to Runner #{runner.id} for #{user_type} #{user_id} and Submission #{id}." }
      runner.copy_files(files)
    rescue Runner::Error => e
      e.waiting_duration = Time.zone.now - request_time
      raise
    end
    waiting_duration = Time.zone.now - request_time
    yield(runner, waiting_duration)
  end

  def swap_runner(old_runner)
    old_runner.update(runner_id: nil)
    new_runner = nil
    new_waiting_duration = nil
    # We request a new runner that will also include all files of the current submission
    prepared_runner do |runner, waiting_duration|
      new_runner = runner
      new_waiting_duration = waiting_duration
    end
    [new_runner, new_waiting_duration]
  end

  def command_for(template, file)
    filepath = collect_files.find {|f| f.filepath == file }.filepath
    template % command_substitutions(filepath)
  end

  def command_substitutions(filename)
    {
      class_name: File.basename(filename, File.extname(filename)).upcase_first,
      filename:,
      module_name: File.basename(filename, File.extname(filename)).underscore,
    }
  end

  def score_file(output, file)
    assessor = Assessor.new(execution_environment:)
    assessment = assessor.assess(output)
    passed = ((assessment[:passed] == assessment[:count]) and (assessment[:score]).positive?)
    testrun_output = passed ? nil : "status: #{output[:status]}\n stdout: #{output[:stdout]}\n stderr: #{output[:stderr]}"
    if testrun_output.present?
      execution_environment.error_templates.each do |template|
        pattern = Regexp.new(template.signature).freeze
        StructuredError.create_from_template(template, testrun_output, self) if pattern.match(testrun_output)
      end
    end
    testrun = Testrun.create(
      submission: self,
      cause: 'assess', # Required to differ run and assess for RfC show
      file:, # Test file that was executed
      passed:,
      exit_code: output[:exit_code],
      status: output[:status],
      output: testrun_output.presence,
      container_execution_time: output[:container_execution_time],
      waiting_for_container_time: output[:waiting_for_container_time]
    )
    TestrunMessage.create_for(testrun, output[:messages])
    TestrunExecutionEnvironment.create(testrun:, execution_environment: @used_execution_environment)

    filename = file.filepath

    if file.teacher_defined_linter?
      LinterCheckRun.create_from(testrun, assessment)
      assessment = assessor.translate_linter(assessment, I18n.locale)

      # replace file name with hint if linter is not used for grading. Refactor!
      filename = I18n.t('exercises.implement.not_graded') if file.weight.zero?
    end

    output.merge!(assessment)
    output.merge!(filename:, message: feedback_message(file, output), weight: file.weight)
    output.except!(:messages)
  end

  def feedback_message(file, output)
    if output[:score] == Assessor::MAXIMUM_SCORE && output[:file_role] == 'teacher_defined_test'
      I18n.t('exercises.implement.default_test_feedback')
    elsif output[:score] == Assessor::MAXIMUM_SCORE && output[:file_role] == 'teacher_defined_linter'
      I18n.t('exercises.implement.default_linter_feedback')
    else
      # The render_markdown method from application_helper.rb is not available in model classes.
      ActionController::Base.helpers.sanitize(
        Kramdown::Document.new(file.feedback_message).to_html,
        tags: %w[strong],
        attributes: []
      )
    end
  end

  def combine_file_scores(outputs)
    score = 0.0
    if outputs.present?
      outputs.each do |output|
        score += output[:score] * output[:weight] unless output.nil?
      end
    end
    # Prevent floating point precision issues by converting to BigDecimal, e.g., for `0.28 * 25`
    update(score: score.to_d)
    if normalized_score.to_d == BigDecimal('1.0')
      Thread.new do
        RequestForComment.where(exercise_id:, user_id:, user_type:).find_each do |rfc|
          rfc.full_score_reached = true
          rfc.save
        end
      rescue StandardError => e
        Sentry.capture_exception(e)
      ensure
        ActiveRecord::Base.connection_pool.release_connection
      end
    end
    if @embed_options.present? && @embed_options[:hide_test_results] && outputs.present?
      outputs.each do |output|
        output.except!(:error_messages, :count, :failed, :filename, :message, :passed, :stderr, :stdout)
      end
    end

    # Return all test results except for those of a linter if not allowed
    show_linter = Python20CourseWeek.show_linter? exercise
    outputs&.reject do |output|
      next if show_linter || output.blank?

      output[:file_role] == 'teacher_defined_linter'
    end
  end
end
