# frozen_string_literal: true

class MoveUpdatedAtIndexToCreatedAtOnSubmission < ActiveRecord::Migration[7.2]
  def change
    remove_index :submissions, :updated_at, order: {updated_at: :desc}
    add_index :submissions, :created_at, order: {updated_at: :desc}
  end
end
