class AddWeightToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :weight, :float
  end
end
