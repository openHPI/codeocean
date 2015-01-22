module SubmissionScoring
  def execute_test_files(submission)
    submission.collect_files.select(&:teacher_defined_test?).map do |file|
      output = @docker_client.execute_test_command(submission, file.name_with_extension)
      output.merge!(@assessor.assess(output))
      output.merge!(filename: file.name_with_extension, message: output[:score] == Assessor::MAXIMUM_SCORE ? I18n.t('exercises.implement.default_feedback') : file.feedback_message, weight: file.weight)
    end
  end
  private :execute_test_files

  def score_submission(submission)
    @assessor = Assessor.new(execution_environment: submission.execution_environment)
    @docker_client = DockerClient.new(execution_environment: submission.execution_environment, user: current_user)
    outputs = execute_test_files(submission)
    score = outputs.map { |output| output[:score] * output[:weight] }.reduce(:+)
    submission.update(score: score)
    outputs
  end
end
