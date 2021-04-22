module SubmissionParameters
  include FileParameters

  def submission_params
    if current_user
      current_user_id = current_user.id
      current_user_class_name = current_user.class.name
    end
    # The study_group_id might not be present in the session (e.g. for internal users), resulting in session[:study_group_id] = nil which is intended.
    submission_params = params[:submission].present? ? params[:submission].permit(:cause, :exercise_id, files_attributes: file_attributes).merge(user_id: current_user_id, user_type: current_user_class_name, study_group_id: session[:study_group_id]) : {}
    files_attributes = submission_params[:files_attributes] || []
    submission_params[:files_attributes] = reject_illegal_file_attributes(submission_params[:exercise_id], files_attributes)
    submission_params
  end
  private :submission_params
end
