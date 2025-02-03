# frozen_string_literal: true

require 'json_schemer'

class RemoteEvaluationController < ApplicationController
  REMOTE_EVALUATION_SCHEMA = JSONSchemer.schema(JSON.parse(File.read('lib/code_ocean/remote-evaluation.schema.json')))

  include Lti
  include ScoringChecks
  include RemoteEvaluationParameters

  skip_before_action :verify_authenticity_token
  skip_before_action :set_sentry_context
  skip_before_action :require_fully_authenticated_user!
  skip_after_action :verify_authorized

  # POST /evaluate
  def evaluate
    result = create_and_score_submission('remoteAssess')
    # For this route, we don't want to display the LTI result, but only the result of the submission.
    try_lti if result.key?(:feedback)
    location = submission_url(@submission) if @submission
    render json: result.fetch(:feedback, result), status: result.fetch(:status, 201), location:
  end

  # POST /submit
  def submit
    result = create_and_score_submission('remoteSubmit')
    result = try_lti if result.key?(:feedback)
    location = submission_url(@submission) if @submission
    render json: result, status: result.fetch(:status, 201), location:
  end

  private

  def try_lti
    lti_responses = send_scores(@submission)
    check_lti_results = check_lti_transmission(lti_responses[:users]) || {}
    score = (@submission.normalized_score * 100).to_i

    # Since we are in an API context, we only want to return a **single** JSON response.
    # For simplicity, we always return the most severe error message.
    if lti_responses[:users][:all] == lti_responses[:users][:unsupported]
      # No LTI transmission was attempted, i.e., no `lis_outcome_service` was provided by the LMS.
      {message: I18n.t('exercises.editor.submit_failure_remote', score:), status: 410, score:}
    elsif check_lti_results[:status] == :scoring_failure
      {message: I18n.t('exercises.editor.submit_failure_all'), status: 424, score:}
    elsif check_lti_results[:status] == :not_for_all_users_submitted
      {message: I18n.t('exercises.editor.submit_failure_other_users', user: check_lti_results[:failed_users]), status: 417, score:}
    elsif check_scoring_too_late(lti_responses).present?
      score_sent = (lti_responses[:score][:sent] * 100).to_i
      {message: I18n.t('exercises.editor.submit_too_late', score_sent:), status: 207, score: score_sent}
    elsif check_full_score.present?
      {message: I18n.t('exercises.editor.exercise_finished_remote', consumer: current_user.consumer.name), status: 200, score:}
    else
      {message: I18n.t('sessions.destroy_through_lti.success_with_outcome', consumer: current_user.consumer.name), status: 202, score:}
    end
  end

  def create_and_score_submission(cause)
    return {message: I18n.t('remote_evaluations.invalid_json'), status: 422} unless valid_submission?

    validation_token = remote_evaluation_params[:validation_token]
    if (remote_evaluation_mapping = RemoteEvaluationMapping.find_by(validation_token:))
      @current_user = remote_evaluation_mapping.user
      @current_contributor = remote_evaluation_mapping.programming_group || remote_evaluation_mapping.user
      @submission = Submission.create(build_submission_params(cause, remote_evaluation_mapping))
      feedback = @submission.calculate_score(remote_evaluation_mapping.user)
      {message: I18n.t('exercises.editor.run_success'), status: 201, feedback:}
    else
      # TODO: better output
      # TODO: check token expired?
      {message: I18n.t('exercises.editor.submit_no_validation_token'), status: 401}
    end
  rescue Runner::Error::RunnerInUse => e
    Rails.logger.debug { "Scoring a submission failed because the runner was already in use: #{e.message}" }
    {message: I18n.t('exercises.editor.runner_in_use'), status: 409}
  rescue Runner::Error => e
    Rails.logger.debug { "Runner error while scoring submission #{@submission.id}: #{e.message}" }
    {message: I18n.t('exercises.editor.depleted'), status: 503}
  end

  def build_submission_params(cause, remote_evaluation_mapping)
    Sentry.set_user(
      id: remote_evaluation_mapping.user_id,
      type: remote_evaluation_mapping.user_type,
      consumer: remote_evaluation_mapping.user.consumer&.name
    )

    files_attributes = remote_evaluation_params[:files_attributes]
    submission_params = remote_evaluation_params.except(:validation_token)
    submission_params[:exercise] = remote_evaluation_mapping.exercise
    submission_params[:contributor] = current_contributor
    submission_params[:study_group_id] = remote_evaluation_mapping.study_group_id
    submission_params[:cause] = cause
    submission_params[:files_attributes] =
      reject_illegal_file_attributes(remote_evaluation_mapping.exercise, files_attributes)
    submission_params
  end

  def valid_submission?
    json_params = JSON.parse(request.raw_post)
    REMOTE_EVALUATION_SCHEMA.valid?(json_params)
  rescue JSON::ParserError
    false
  end
end
