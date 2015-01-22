class AddWeightToFiles < ActiveRecord::Migration
  def change
    add_column :files, :weight, :float
  end
end
