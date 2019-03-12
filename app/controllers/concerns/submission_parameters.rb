module SubmissionParameters
  include FileParameters

  def reject_illegal_file_attributes!(submission_params)
    if Exercise.exists?(id: submission_params[:exercise_id])
      submission_params[:files_attributes].try(:reject!) do |_, file_attributes|
        file = CodeOcean::File.find_by(id: file_attributes[:file_id])
        file.nil? || file.hidden || file.read_only
      end
    end
  end
  private :reject_illegal_file_attributes!

  def submission_params
    if current_user
      current_user_id = current_user.id
      current_user_class_name = current_user.class.name
    end
    # The study_group_id might not be present in the session (e.g. for internal users), resulting in session[:study_group_id] = nil which is intended.
    submission_params = params[:submission].present? ? params[:submission].permit(:cause, :exercise_id, files_attributes: file_attributes).merge(user_id: current_user_id, user_type: current_user_class_name, study_group_id: session[:study_group_id]) : {}
    reject_illegal_file_attributes!(submission_params)
    submission_params
  end
  private :submission_params
end
