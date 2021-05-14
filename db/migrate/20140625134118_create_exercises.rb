# frozen_string_literal: true

class CreateExercises < ActiveRecord::Migration[4.2]
  def change
    create_table :exercises do |t|
      t.text :description
      t.belongs_to :execution_environment
      t.text :template_code
      t.string :title
      t.timestamps
    end
  end
end
