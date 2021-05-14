# frozen_string_literal: true

class CreateExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    create_table :execution_environments do |t|
      t.string :docker_image
      t.string :editor_mode
      t.string :file_extension
      t.string :name
      t.timestamps
    end
  end
end
