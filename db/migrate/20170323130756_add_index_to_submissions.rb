# frozen_string_literal: true

class AddIndexToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_index :submissions, :exercise_id
    add_index :submissions, :user_id
  end
end
