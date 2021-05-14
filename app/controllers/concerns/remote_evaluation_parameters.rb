# frozen_string_literal: true

module RemoteEvaluationParameters
  include FileParameters

  def remote_evaluation_params
    if params[:remote_evaluation].present?
      params[:remote_evaluation].permit(:validation_token, files_attributes: file_attributes)
    end
  end
  private :remote_evaluation_params
end
