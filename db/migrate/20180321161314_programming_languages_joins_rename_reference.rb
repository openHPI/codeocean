class ProgrammingLanguagesJoinsRenameReference < ActiveRecord::Migration
  def change
    remove_reference :programming_languages_joins, :programming_languages, index: true
    add_reference :programming_languages_joins, :programming_language, index: true
  end
end
