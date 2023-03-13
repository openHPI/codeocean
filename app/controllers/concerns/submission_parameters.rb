# frozen_string_literal: true

module SubmissionParameters
  include FileParameters

  def submission_params
    submission_params = if params[:submission].present?
                          params[:submission].permit(:cause, :exercise_id,
                            files_attributes: file_attributes)
                        else
                          {}
                        end
    submission_params = merge_user(submission_params)
    files_attributes = submission_params[:files_attributes]
    exercise = @exercise || Exercise.find_by(id: submission_params[:exercise_id])
    submission_params[:files_attributes] = reject_illegal_file_attributes(exercise, files_attributes)
    submission_params[:exercise] = exercise
    submission_params
  end
  private :submission_params

  def merge_user(params)
    # The study_group_id might not be present in the session (e.g. for internal users), resulting in session[:study_group_id] = nil which is intended.
    params.merge(
      user: current_user,
      study_group_id: current_user.current_study_group_id
    )
  end
end
