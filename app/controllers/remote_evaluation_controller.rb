class RemoteEvaluationController < ApplicationController
  include RemoteEvaluationParameters
  include SubmissionScoring

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token

  # POST /evaluate
  # @param validation_token
  # @param files_attributes
  def evaluate

    validation_token = remote_evaluation_params[:validation_token]
    files_attributes = remote_evaluation_params[:files_attributes] || []

    # todo extra: validiere, ob files wirklich zur Übung gehören (wenn allowNewFiles-flag nicht gesetzt ist)
    if (remote_evaluation_mapping = RemoteEvaluationMapping.find_by(:validation_token => validation_token))
      puts remote_evaluation_mapping.exercise_id
      puts remote_evaluation_mapping.user_id

      _params = remote_evaluation_params.except(:validation_token)
      _params[:exercise_id] = remote_evaluation_mapping.exercise_id
      _params[:user_id] = remote_evaluation_mapping.user_id
      _params[:cause] = "remoteAssess"
      _params[:user_type] = "ExternalUser"

      @submission = Submission.create(_params)
      render json: score_submission(@submission)
    else
      # todo: better output
      # todo: check token expired?
      render json: "No exercise found for this validation_token! Please keep out!"
    end
  end
end