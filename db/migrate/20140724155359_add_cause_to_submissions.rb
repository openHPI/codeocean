class AddCauseToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :cause, :string
  end
end
