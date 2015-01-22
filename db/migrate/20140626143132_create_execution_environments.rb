class CreateExecutionEnvironments < ActiveRecord::Migration
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
