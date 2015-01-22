class AddUserTypeToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :user_type, :string
  end
end
