module ActionCableHelper
  def trigger_rfc_action_cable
    if submission.study_group_id.present?
      ActionCable.server.broadcast(
        "la_exercises_#{exercise_id}_channel_study_group_#{submission.study_group_id}",
        id: id,
        html: (ApplicationController.render(partial: 'request_for_comments/list_entry',
                                            locals: {request_for_comment: self})))
    end
  end

  def trigger_rfc_action_cable_from_comment
    RequestForComment.find_by(submission: file.context).trigger_rfc_action_cable
  end
end
