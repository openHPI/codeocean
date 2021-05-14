# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[4.2]
  def change
    create_table :teams do |t|
      t.string :name
      t.timestamps
    end
  end
end
