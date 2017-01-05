class RemoteEvaluationController < ApplicationController

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token

  # POST /remote_evaluation/evaluate
  # @param token
  # @exercise_files
  def evaluate
    token = params[:token]
    # im Model nachgucken, ob es zu diesem token einen user und eine exerciseId gibt
    # wenn ja ausführen
    ## @exercise_files (entpacken, stream entziffern was auch immer)
    ##
    # wenn nein und token expired (nach einem Monat): sende antwort, dass token expired und: Log dich ein, suche Übung und update das token
    render :nothing => true
  end
end
