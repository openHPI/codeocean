class RemoteEvaluationController < ApplicationController
  include RemoteEvaluationParameters
  include SubmissionScoring
  include Lti

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token

  # POST /evaluate
  def evaluate
    result = create_and_score_submission("remoteAssess")
    status = if result.is_a?(Hash) && result.has_key?(:status)
               result[:status]
               else
                 201
             end
    render json: result, status: status
  end

  # POST /submit
  def submit
    result = create_and_score_submission("remoteSubmit")

    if @submission.present?
      current_user = @submission.user
      if !current_user.nil? && lti_outcome_service?(@submission.exercise_id, current_user.id, current_user.consumer_id)
        lti_response = send_score(@submission)

        if lti_response[:status] == 'success' and lti_response[:score_sent] != @submission.normalized_score
          # Score has been reduced due to the passed deadline
          result = {message: I18n.t('exercises.submit.too_late'), status: 207}
        elsif lti_response[:status] == 'success'
          result = {message: I18n.t('sessions.destroy_through_lti.success_with_outcome', consumer: @submission.user.consumer.name), status: 202}
        else
          result = {message: I18n.t('exercises.submit.failure'), status: 424}
        end
        # ToDo: Delete LTI parameters?
      else
        result = {message: "Your submission was successfully scored with #{@submission.normalized_score * 100}%. However, your score could not be sent to the e-Learning platform. Please reopen the exercise through the e-Learning platform and try again.", status: 410}
      end
    end

    status = if result.is_a?(Hash) && result.has_key?(:status)
               result[:status]
             else
               201
             end

    render json: result, status: status
  end

  def create_and_score_submission cause
    validation_token = remote_evaluation_params[:validation_token]
    files_attributes = remote_evaluation_params[:files_attributes] || []

    # todo extra: validiere, ob files wirklich zur Übung gehören (wenn allowNewFiles-flag nicht gesetzt ist)
    if (remote_evaluation_mapping = RemoteEvaluationMapping.find_by(:validation_token => validation_token))

      _params = remote_evaluation_params.except(:validation_token)
      _params[:exercise_id] = remote_evaluation_mapping.exercise_id
      _params[:user_id] = remote_evaluation_mapping.user_id
      _params[:cause] = cause
      _params[:user_type] = remote_evaluation_mapping.user_type

      @submission = Submission.create(_params)
      score_submission(@submission)
    else
      # todo: better output
      # todo: check token expired?
      {message: "No exercise found for this validation_token! Please keep out!", status: 401}
    end
  end
  private :create_and_score_submission
end