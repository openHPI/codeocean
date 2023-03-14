# frozen_string_literal: true

class AddIndexForRecommendedRfcs < ActiveRecord::Migration[7.0]
  def change
    add_index :request_for_comments, %i[exercise_id created_at], where: "(NOT solved OR solved IS NULL) AND (question IS NOT NULL AND question <> '')", name: :index_unresolved_recommended_rfcs
  end
end
