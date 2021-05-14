# frozen_string_literal: true

class AddNormalizedScoreAndSubmissionToUserExerciseFeedback < ActiveRecord::Migration[5.2]
  def change
    add_column :user_exercise_feedbacks, :normalized_score, :float
    add_reference :user_exercise_feedbacks, :submission, foreign_key: true

    # Disable automatic timestamp modification
    ActiveRecord::Base.record_timestamps = false
    UserExerciseFeedback.all.find_each do |uef|
      latest_submission = Submission
        .where(user_id: uef.user_id, user_type: uef.user_type, exercise_id: uef.exercise_id)
        .where('created_at < ?', uef.updated_at)
        .order(created_at: :desc).first

      # In the beginning, CodeOcean allowed feedback for exercises while viewing an RfC. As a RfC
      # might be opened by any registered learner, feedback for exercises was created by learners
      # without having any submission for this particular exercise.
      next if latest_submission.nil?

      uef.update(submission: latest_submission, normalized_score: latest_submission.normalized_score)
    end
    ActiveRecord::Base.record_timestamps = true
  end
end
