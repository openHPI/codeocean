class CreateProgrammingLanguages < ActiveRecord::Migration
  def change
    create_table :programming_languages do |t|
      t.string :version
      t.string :name
      t.timestamps null: false
    end
  end
end
