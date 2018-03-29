class RenameProgrammingLanguagesMapToProgrammingLanguagesJoins < ActiveRecord::Migration
  def change
    rename_table :programming_languages_map, :programming_languages_joins
  end
end
