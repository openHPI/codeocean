# frozen_string_literal: true

class RemoveEventIndices < ActiveRecord::Migration[6.1]
  def change
    remove_index :events, %i[user_type user_id], if_exists: true
    remove_index :events, :exercise_id, if_exists: true
    remove_index :events, :file_id, if_exists: true
  end
end
