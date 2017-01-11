class RemoteEvaluationController < ApplicationController
  include RemoteEvaluationParameters

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token

  # POST /evaluate
  # @param validation_token
  # @param files_attributes
  def evaluate

    puts params

    validation_token = remote_evaluation_params[:validation_token]
    files_attributes = remote_evaluation_params[:files_attributes] || []

    # todo extra: validiere, ob files wirklich zur Übung gehören (wenn allowNewFiles-flag nicht gesetzt ist)
    if (remote_evaluation_mapping = RemoteEvaluationMapping.find_by(:validation_token => validation_token))
      puts remote_evaluation_mapping.exercise_id
      puts remote_evaluation_mapping.user_id

      ## submission erstellen (submission create) mit cause "remoteAssess", file_attributes: { Array of {name: Dateiname, content: Inhalt der Datei} } und exercise_id
      # todo: create instead of new to save in db!
      @submission = Submission.new(remote_evaluation_params.except(:validation_token))
      @submission.exercise_id = remote_evaluation_mapping.exercise_id
      @submission.user_id = remote_evaluation_mapping.user_id
      @submission.cause = "remoteAssess"
      @submission.save
      render json: @submission
    else
      # todo: better output
      # todo: check token expired?
      render json: "No exercise found for this validation_token! Please keep out!"
    end
  end
end
