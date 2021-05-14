# frozen_string_literal: true

class CreateSubmissions < ActiveRecord::Migration[4.2]
  def change
    create_table :submissions do |t|
      t.text :code
      t.belongs_to :exercise
      t.float :score
      t.belongs_to :user
      t.timestamps
    end
  end
end
