class CreateExecutionEnvironmentsProgrammingLanguages < ActiveRecord::Migration
  def change
    create_table :programming_languages_joins do |t|
      t.belongs_to :execution_environment, index: true
      t.belongs_to :programming_language, index: true
      t.boolean :default
    end
  end
end
