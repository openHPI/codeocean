# frozen_string_literal: true

class CreateStudyGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :study_groups do |t|
      t.string :name
      t.string :external_id
      t.belongs_to :consumer
      t.timestamps
    end

    add_index :study_groups, %i[external_id consumer_id], unique: true
  end
end
