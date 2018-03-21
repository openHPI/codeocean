class CreateProgrammingLanguages < ActiveRecord::Migration
  def change
    create_table :programming_languages do |t|
      t.string :version
      t.string :name
      t.references :execution_environment, index: true, foreign_key: true
      t.boolean :default

      t.timestamps null: false
    end
  end
end
