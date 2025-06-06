# frozen_string_literal: true

class Submission < ApplicationRecord
  include Context
  include ContributorCreation
  include ActionCableHelper

  CAUSES = %w[assess download file render run save submit test autosave requestComments remoteAssess
              remoteSubmit].freeze
  MAX_COMMENTS_ON_RECOMMENDED_RFC = 5
  OLDEST_RFC_TO_SHOW = 1.month

  belongs_to :exercise
  belongs_to :study_group, optional: true

  has_many :testruns
  has_many :structured_errors, dependent: :destroy
  has_many :comments, through: :files
  has_one :request_for_comment
  has_one :user_exercise_feedback
  has_one :pair_programming_exercise_feedback

  belongs_to :external_users, lambda {
                                where(submissions: {contributor_type: 'ExternalUser'}).includes(:submissions)
                              }, foreign_key: :contributor_id, class_name: 'ExternalUser', optional: true
  belongs_to :internal_users, lambda {
                                where(submissions: {contributor_type: 'InternalUser'}).includes(:submissions)
                              }, foreign_key: :contributor_id, class_name: 'InternalUser', optional: true
  belongs_to :programming_groups, lambda {
                                    where(submissions: {contributor_type: 'ProgrammingGroup'}).includes(:submissions)
                                  }, foreign_key: :contributor_id, class_name: 'ProgrammingGroup', optional: true
  delegate :execution_environment, to: :exercise

  scope :final, -> { where(cause: %w[submit remoteSubmit]) }
  scope :intermediate, -> { where.not(cause: %w[submit remoteSubmit]) }

  scope :before_deadline, lambda {
                            joins(:exercise).where('submissions.created_at <= exercises.submission_deadline OR exercises.submission_deadline IS NULL')
                          }
  scope :within_grace_period, lambda {
                                joins(:exercise).where('(submissions.created_at > exercises.submission_deadline) AND (submissions.created_at <= exercises.late_submission_deadline OR exercises.late_submission_deadline IS NULL)')
                              }
  scope :after_late_deadline, lambda {
                                joins(:exercise).where('submissions.created_at > exercises.late_submission_deadline')
                              }

  scope :latest, -> { order(submissions: {created_at: :desc}).first }

  validates :cause, inclusion: {in: CAUSES}

  # after_save :trigger_working_times_action_cable

  def collect_files
    @collect_files ||= begin
      ancestors = build_files_hash(exercise&.files&.includes(:file_type), :id)
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

  def full_score?
    score == exercise.maximum_score
  end

  def normalized_score
    @normalized_score ||= if !score.nil? && !exercise.maximum_score.nil? && exercise.maximum_score.positive?
                            score / exercise.maximum_score
                          else
                            0
                          end
  end

  def percentage
    (normalized_score * 100).round
  end

  def siblings
    contributor.submissions.where(exercise_id:)
  end

  def to_s
    Submission.model_name.human
  end

  def before_deadline?
    if exercise.submission_deadline.present?
      created_at <= exercise.submission_deadline
    else
      false
    end
  end

  def within_grace_period?
    if exercise.submission_deadline.present? && exercise.late_submission_deadline.present?
      created_at > exercise.submission_deadline && created_at <= exercise.late_submission_deadline
    else
      false
    end
  end

  def after_late_deadline?
    if exercise.late_submission_deadline.present?
      created_at > exercise.late_submission_deadline
    elsif exercise.submission_deadline.present?
      created_at > exercise.submission_deadline
    else
      false
    end
  end

  def redirect_to_feedback?
    # Redirect 10% of users to the exercise feedback page. Ensure, that always the same
    # users get redirected per exercise and different users for different exercises. If
    # desired, the number of feedbacks can be limited with exercise.needs_more_feedback?
    (contributor_id + exercise.created_at.to_i) % 10 == 1
  end

  def own_unsolved_rfc(user)
    Pundit.policy_scope(user, RequestForComment).joins(:submission).where(submission: {contributor:}).unsolved.find_by(exercise:)
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
  def calculate_score(requesting_user)
    file_scores = nil
    # If prepared_runner raises an error, no Testrun will be created.
    prepared_runner do |runner, waiting_duration|
      assessments = collect_files.select(&:teacher_defined_assessment?)
      assessment_number = assessments.size

      # We sort the test files, so that the linter checks are run first. This prevents a modification of the test file
      file_scores = assessments.sort_by {|file| file.teacher_defined_linter? ? 0 : 1 }.map.with_index(1) do |file, index|
        output = run_file :test_command, file, runner, waiting_duration
        # If the previous execution failed and there is at least one more test, we request a new runner.
        swap_runner(runner) if output[:status] == :timeout && index < assessment_number
        score_file(output, file, requesting_user)
      end
    end
    # We sort the files again, so that *optional* linter tests are displayed last.
    # All other files are sorted alphabetically.
    file_scores&.sort_by! do |file|
      [file[:file_role] == 'teacher_defined_linter' && file[:weight].zero? ? 1 : 0, file[:filename]]
    end
    combine_file_scores(file_scores)
  end

  # @raise [Runner::Error] if the code could not be run due to a failure with the runner.
  #                        See the specific type and message for more details.
  def run(file, &)
    run_command = command_for execution_environment.run_command, file.filepath
    durations = {}
    prepared_runner do |runner, waiting_duration|
      durations[:execution_duration] = runner.attach_to_execution(run_command, exclusive: false, &)
      durations[:waiting_duration] = waiting_duration
    rescue Runner::Error => e
      e.waiting_duration = waiting_duration
      raise
    end
    durations
  end

  def test(file, requesting_user)
    output = execute :test_command, file
    score_file output, file, requesting_user
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[study_group_id exercise_id cause]
  end

  def users
    contributor.try(:users) || [contributor]
  end

  private

  def build_files_hash(files, attribute)
    files&.map(&attribute.to_proc)&.zip(files).to_h
  end

  def prepared_runner(existing_runner: nil, exclusive: true)
    request_time = Time.zone.now
    begin
      runner = existing_runner || Runner.for(contributor, exercise.execution_environment)
      runner.reserve! if exclusive
      files = collect_files

      case cause
        when 'run', 'test'
          files.reject! do |file|
            next true if file.reference_implementation?
            # Only remove teacher-defined assessments if they are hidden.
            # Otherwise, 'test' might fail if a teacher-defined assessment is executed.
            next true if file.teacher_defined_assessment? && file.hidden?

            next false
          end
        when 'assess', 'submit', 'remoteAssess', 'remoteSubmit', 'requestComments'
          regular_filepaths = files.reject(&:reference_implementation?).map(&:filepath)
          files.reject! {|file| file.reference_implementation? && regular_filepaths.include?(file.filepath) }
      end

      Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Copying files to Runner #{runner.id} for #{contributor_type} #{contributor_id} and Submission #{id}." }
      # We don't want `copy_files` to be exclusive since we reserve runners for the whole `prepared_runner` block.
      runner.copy_files(files, exclusive: false)
    rescue Runner::Error => e
      e.waiting_duration = Time.zone.now - request_time
      raise
    end
    waiting_duration = Time.zone.now - request_time
    yield(runner, waiting_duration) if block_given?
  ensure
    runner&.release! if exclusive
  end

  def swap_runner(runner, exclusive: true)
    # We use a transaction to ensure that the runner is swapped atomically.
    transaction do
      # Due to the `before_validation` callback in the `Runner` model,
      # the following line will immediately request a new runner.
      runner.update(runner_id: nil)

      # With the new runner being ready, we only need to prepare it (by copying the files).
      # Since no actual execution is performed, we don't need to reserve the runner.
      prepared_runner(existing_runner: runner, exclusive: false)

      # Now, we update the locks if desired. This is only necessary when a runner is used exclusively.
      runner.extend! if exclusive
    end
  end

  def command_for(template, filepath)
    template % command_substitutions(filepath)
  end

  def command_substitutions(filename)
    {
      class_name: File.basename(filename, File.extname(filename)).upcase_first,
      filename:,
      module_name: File.basename(filename, File.extname(filename)).underscore,
    }
  end

  # @raise [Runner::Error] if the file could not be tested due to a failure with the runner.
  #                        See the specific type and message for more details.
  def execute(action, file)
    prepared_runner do |runner, waiting_duration|
      run_file action, file, runner, waiting_duration
    rescue Runner::Error => e
      e.waiting_duration = waiting_duration
      raise
    end
  end

  def run_file(action, file, runner, waiting_duration)
    command = command_for execution_environment.public_send(action), file.filepath
    result = {file_role: file.role, waiting_for_container_time: waiting_duration}
    output = runner.execute_command(command, raise_exception: false, exclusive: false)
    result.merge(output)
  end

  def score_file(output, file, requesting_user)
    assessor = Assessor.new(execution_environment:)
    assessment = assessor.assess(output)
    passed = (assessment[:passed] == assessment[:count]) && assessment[:score].positive?
    testrun_output = passed ? nil : "status: #{output[:status]}\n stdout: #{output[:stdout]}\n stderr: #{output[:stderr]}"
    if testrun_output.present?
      execution_environment.error_templates.each do |template|
        pattern = Regexp.new(template.signature).freeze
        StructuredError.create_from_template(template, testrun_output, self) if pattern.match(testrun_output)
      end
    end
    testrun = Testrun.create(
      submission: self,
      user: requesting_user,
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

    filename = file.filepath

    if file.teacher_defined_linter?
      LinterCheckRun.create_from(testrun, assessment)
      assessment = assessor.translate_linter(assessment, I18n.locale)

      # replace file name with hint if linter is not used for grading. Refactor!
      filename = I18n.t('exercises.implement.not_graded') if file.weight.zero?
    end

    output.merge!(assessment)
    output.merge!(filename:, message: feedback_message(file, output), weight: file.weight, hidden_feedback: file.hidden_feedback)
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
        Kramdown::Document.new(file.feedback_message, smart_quotes: 'apos,apos,quot,quot').to_html,
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
        RequestForComment.joins(:submission).where(submission: {contributor:}, exercise:).find_each do |rfc|
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

    outputs&.reject {|output| output[:hidden_feedback] if output.present? }
  end
end
