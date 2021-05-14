# frozen_string_literal: true

class CreateInterventions < ActiveRecord::Migration[4.2]
  def change
    create_table :user_exercise_interventions do |t|
      t.belongs_to :user, polymorphic: true
      t.belongs_to :exercise
      t.belongs_to :intervention
      t.integer :accumulated_worktime_s
      t.text :reason
      t.timestamps
    end

    create_table :interventions do |t|
      t.string :name
      t.text :markup
      t.timestamps
    end

    Intervention.create_default_interventions
  end
end
