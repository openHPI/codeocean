class RemoteEvaluationController < ApplicationController

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token

  # POST /evaluate
  # @param validation_token
  # @param file_attributes
  def evaluate
    validation_token = params[:validation_token]
    files_attributes = params[:files_attributes] || []

    # todo extra: validiere, ob files wirklich zur Übung gehören (wenn allowNewFiles-flag nicht gesetzt ist)
    if (remote_evaluation_mapping = RemoteEvaluationMapping.find_by(:validation_token => validation_token))
      puts remote_evaluation_mapping.exercise_id
      puts remote_evaluation_mapping.user_id

      ## submission erstellen (submission create) mit cause "remoteAssess", fileAttributes: { Array of {name: Dateiname, content: Inhalt der Datei} } und exercise_id
      submission = Submission.new(:cause => 'remoteAssess', :files_attributes => files_attributes) # todo: create instead of new to save in db!
      render json: submission
    else
      # todo: better output
      # todo: check token expired?
      render json: "No exercise found for this validation_token! Please keep out!"
    end
  end
end
