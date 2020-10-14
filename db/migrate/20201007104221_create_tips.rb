# frozen_string_literal: true

class CreateTips < ActiveRecord::Migration[5.2]
  def change
    create_table :tips do |t|
      t.string :title
      t.text :description
      t.text :example
      t.references :file_type, foreign_key: true
      t.references :user, polymorphic: true, null: false
      t.timestamps
    end

    create_table :exercise_tips do |t|
      t.references :exercise, null: false, foreign_key: true
      t.references :tip, null: false, foreign_key: true
      t.integer :rank, null: false
      t.references :parent_exercise_tip, foreign_key: {to_table: :exercise_tips}
      t.index %i[exercise_id rank]
    end
  end
end
