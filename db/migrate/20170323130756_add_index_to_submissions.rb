class AddIndexToSubmissions < ActiveRecord::Migration
  def change
    add_index :submissions, :exercise_id
    add_index :submissions, :user_id
  end
end
