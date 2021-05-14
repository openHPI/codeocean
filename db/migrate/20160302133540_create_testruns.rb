# frozen_string_literal: true

class CreateTestruns < ActiveRecord::Migration[4.2]
  def change
    create_table :testruns do |t|
      t.boolean :passed
      t.text :output

      t.belongs_to :file
      t.belongs_to :submission

      t.timestamps
    end
  end
end
