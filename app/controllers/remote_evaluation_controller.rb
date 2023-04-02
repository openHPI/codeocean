# frozen_string_literal: true

class RemoteEvaluationController < ApplicationController
  include RemoteEvaluationParameters
  include Lti

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
  skip_before_action :set_sentry_context

  # POST /evaluate
  def evaluate
    result = create_and_score_submission('remoteAssess')
    status = if result.is_a?(Hash) && result.key?(:status)
               result[:status]
             else
               201
             end
    render json: result, status:
  end

  # POST /submit
  def submit
    result = create_and_score_submission('remoteSubmit')
    status = 201
    if @submission.present?
      score_achieved_percentage = @submission.normalized_score
      result = try_lti
      result[:score] = score_achieved_percentage * 100 unless result[:score]
      status = result[:status]
    end

    render json: result, status:
  end

  def try_lti
    if !@submission.user.nil? && lti_outcome_service?(@submission.exercise_id, @submission.user.id)
      lti_response = send_score(@submission)
      process_lti_response(lti_response)
    else
      {
        message: "Your submission was successfully scored with #{@submission.normalized_score * 100}%. " \
                 'However, your score could not be sent to the e-Learning platform. Please check ' \
                 'the submission deadline, reopen the exercise through the e-Learning platform and try again.',
        status: 410,
      }
    end
  end
  private :try_lti

  def process_lti_response(lti_response)
    if (lti_response[:status] == 'success') && (lti_response[:score_sent] != @submission.normalized_score)
      # Score has been reduced due to the passed deadline
      {message: I18n.t('exercises.submit.too_late'), status: 207, score: lti_response[:score_sent] * 100}
    elsif lti_response[:status] == 'success'
      {message: I18n.t('sessions.destroy_through_lti.success_with_outcome', consumer: @submission.user.consumer.name), status: 202}
    else
      {message: I18n.t('exercises.submit.failure'), status: 424}
    end
    # TODO: Delete LTI parameters?
  end
  private :process_lti_response

  def create_and_score_submission(cause)
    validation_token = remote_evaluation_params[:validation_token]
    if (remote_evaluation_mapping = RemoteEvaluationMapping.find_by(validation_token:))
      @submission = Submission.create(build_submission_params(cause, remote_evaluation_mapping))
      @submission.calculate_score
    else
      # TODO: better output
      # TODO: check token expired?
      {message: 'No exercise found for this validation_token! Please keep out!', status: 401}
    end
  rescue Runner::Error => e
    Rails.logger.debug { "Runner error while scoring submission #{@submission.id}: #{e.message}" }
    {message: I18n.t('exercises.editor.depleted'), status: 503}
  end
  private :create_and_score_submission

  def build_submission_params(cause, remote_evaluation_mapping)
    Sentry.set_user(
      id: remote_evaluation_mapping.user_id,
      type: remote_evaluation_mapping.user_type,
      consumer: remote_evaluation_mapping.user.consumer&.name
    )

    files_attributes = remote_evaluation_params[:files_attributes]
    submission_params = remote_evaluation_params.except(:validation_token)
    submission_params[:exercise] = remote_evaluation_mapping.exercise
    submission_params[:user] = remote_evaluation_mapping.user
    submission_params[:study_group_id] = remote_evaluation_mapping.study_group_id
    submission_params[:cause] = cause
    submission_params[:files_attributes] =
      reject_illegal_file_attributes(remote_evaluation_mapping.exercise, files_attributes)
    submission_params
  end
  private :build_submission_params
end
