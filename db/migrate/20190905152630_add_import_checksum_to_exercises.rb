class AddImportChecksumToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :import_checksum, :string
  end
end
