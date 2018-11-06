module RemoteEvaluationParameters
  include FileParameters

  def remote_evaluation_params
    remote_evaluation_params = params[:remote_evaluation].permit(:validation_token, files_attributes: file_attributes) if params[:remote_evaluation].present?
  end
  private :remote_evaluation_params
end