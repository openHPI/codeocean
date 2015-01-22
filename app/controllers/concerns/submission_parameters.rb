module SubmissionParameters
  include FileParameters

  def reject_illegal_file_attributes!(submission_params)
    if exercise = Exercise.find_by(id: submission_params[:exercise_id])
      submission_params[:files_attributes].try(:reject!) do |index, file_attributes|
        file = CodeOcean::File.find_by(id: file_attributes[:file_id])
        file.nil? || file.hidden || file.read_only
      end
    end
  end
  private :reject_illegal_file_attributes!

  def submission_params
    submission_params = params[:submission].permit(:cause, :exercise_id, files_attributes: file_attributes).merge(user_id: current_user.id, user_type: current_user.class.name)
    reject_illegal_file_attributes!(submission_params)
    submission_params
  end
  private :submission_params
end
