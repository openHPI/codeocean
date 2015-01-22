class RemoveCodeFromSubmissions < ActiveRecord::Migration
  def change
    remove_column :submissions, :code, :text
  end
end
