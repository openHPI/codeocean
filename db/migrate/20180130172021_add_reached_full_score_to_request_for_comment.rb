class AddReachedFullScoreToRequestForComment < ActiveRecord::Migration
  def up
    add_column :request_for_comments, :full_score_reached, :boolean, default: false
    RequestForComment.find_each { |rfc|
      if rfc.submission.present? and rfc.submission.exercise.has_user_solved(rfc.user)
        rfc.full_score_reached = true
        rfc.save
      end
    }
  end

  def down
    remove_column :request_for_comments, :full_score_reached
  end
end
