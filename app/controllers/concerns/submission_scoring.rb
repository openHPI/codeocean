# frozen_string_literal: true

require 'concurrent/future'

module SubmissionScoring
  def collect_test_results(submission)
    # Mnemosyne.trace 'custom.codeocean.collect_test_results', meta: { submission: submission.id } do
    futures = submission.collect_files.select(&:teacher_defined_assessment?).map do |file|
      Concurrent::Future.execute do
        # Mnemosyne.trace 'custom.codeocean.collect_test_results_block', meta: { file: file.id, submission: submission.id } do
        assessor = Assessor.new(execution_environment: submission.execution_environment)
        output = execute_test_file(file, submission)
        assessment = assessor.assess(output)
        passed = ((assessment[:passed] == assessment[:count]) and (assessment[:score]).positive?)
        testrun_output = passed ? nil : "status: #{output[:status]}\n stdout: #{output[:stdout]}\n stderr: #{output[:stderr]}"
        if testrun_output.present?
          submission.exercise.execution_environment.error_templates.each do |template|
            pattern = Regexp.new(template.signature).freeze
            StructuredError.create_from_template(template, testrun_output, submission) if pattern.match(testrun_output)
          end
        end
        testrun = Testrun.create(
          submission: submission,
          cause: 'assess', # Required to differ run and assess for RfC show
          file: file, # Test file that was executed
          passed: passed,
          output: testrun_output,
          container_execution_time: output[:container_execution_time],
          waiting_for_container_time: output[:waiting_for_container_time]
        )

        filename = file.name_with_extension

        if file.teacher_defined_linter?
          LinterCheckRun.create_from(testrun, assessment)
          switch_locale do
            assessment = assessor.translate_linter(assessment, I18n.locale)

            # replace file name with hint if linter is not used for grading. Refactor!
            filename = t('exercises.implement.not_graded') if file.weight.zero?
          end
        end

        output.merge!(assessment)
        output.merge!(filename: filename, message: feedback_message(file, output), weight: file.weight)
        # end
      end
    end
    futures.map(&:value)
  end

  private :collect_test_results

  def execute_test_file(file, submission)
    DockerClient.new(execution_environment: file.context.execution_environment).execute_test_command(submission,
      file.name_with_extension)
  end

  private :execute_test_file

  def feedback_message(file, output)
    switch_locale do
      if output[:score] == Assessor::MAXIMUM_SCORE && output[:file_role] == 'teacher_defined_test'
        I18n.t('exercises.implement.default_test_feedback')
      elsif output[:score] == Assessor::MAXIMUM_SCORE && output[:file_role] == 'teacher_defined_linter'
        I18n.t('exercises.implement.default_linter_feedback')
      else
        render_markdown(file.feedback_message)
      end
    end
  end

  def score_submission(submission)
    outputs = collect_test_results(submission)
    score = 0.0
    if outputs.present?
      outputs.each do |output|
        score += output[:score] * output[:weight] unless output.nil?

        if output.present? && output[:status] == :timeout
          output[:stderr] += "\n\n#{t('exercises.editor.timeout',
            permitted_execution_time: submission.exercise.execution_environment.permitted_execution_time.to_s)}"
        end
      end
    end
    submission.update(score: score)
    if submission.normalized_score.to_d == 1.0.to_d
      Thread.new do
        RequestForComment.where(exercise_id: submission.exercise_id, user_id: submission.user_id,
          user_type: submission.user_type).each do |rfc|
          rfc.full_score_reached = true
          rfc.save
        end
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
    show_linter = Python20CourseWeek.show_linter? submission.exercise
    outputs&.reject do |output|
      next if show_linter || output.blank?

      output[:file_role] == 'teacher_defined_linter'
    end
  end
end
