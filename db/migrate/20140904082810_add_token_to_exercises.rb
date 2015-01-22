class AddTokenToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :token, :string
  end
end
