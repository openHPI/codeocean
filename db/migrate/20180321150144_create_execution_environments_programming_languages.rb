class CreateExecutionEnvironmentsProgrammingLanguages < ActiveRecord::Migration
  def change
    remove_reference(:programming_languages, :execution_environment, index: true, foreign_key: true)
    remove_column(:programming_languages, :default)
    create_table :programming_languages_map do |t|
      t.belongs_to :execution_environment, index: true
      t.belongs_to :programming_languages, index: true
      t.boolean :default
    end
  end
end
