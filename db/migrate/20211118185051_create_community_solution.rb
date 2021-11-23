# frozen_string_literal: true

class CreateCommunitySolution < ActiveRecord::Migration[6.1]
  def change
    create_table :community_solutions do |t|
      t.belongs_to :exercise, foreign_key: true, null: false, index: true

      t.timestamps
    end

    create_table :community_solution_locks do |t|
      t.belongs_to :community_solution, foreign_key: true, null: false, index: false
      t.references :user, polymorphic: true, null: false
      t.timestamp :locked_until, null: true

      t.timestamps

      t.index %i[community_solution_id locked_until], unique: true, name: 'index_community_solution_locks_until'
    end

    create_table :community_solution_contributions do |t|
      t.belongs_to :community_solution, foreign_key: true, null: false, index: false
      t.belongs_to :study_group, foreign_key: true, null: true, index: false
      t.references :user, polymorphic: true, null: false
      t.belongs_to :community_solution_lock, foreign_key: true, null: false, index: {name: 'index_community_solution_contributions_lock'}
      t.boolean :proposed_changes, null: false
      t.boolean :timely_contribution, null: false
      t.boolean :autosave, null: false
      t.interval :working_time, null: false

      t.timestamps

      t.index %i[community_solution_id timely_contribution autosave proposed_changes], name: 'index_community_solution_valid_contributions'
    end
  end
end
