# frozen_string_literal: true

class AddReachedFullScoreToRequestForComment < ActiveRecord::Migration[4.2]
  def up
    add_column :request_for_comments, :full_score_reached, :boolean, default: false
    RequestForComment.find_each do |rfc|
      if rfc.submission.present? && rfc.submission.exercise.solved_by?(rfc.user)
        rfc.full_score_reached = true
        rfc.save
      end
    end
  end

  def down
    remove_column :request_for_comments, :full_score_reached
  end
end
