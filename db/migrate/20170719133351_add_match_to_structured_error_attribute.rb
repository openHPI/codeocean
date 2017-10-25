class AddMatchToStructuredErrorAttribute < ActiveRecord::Migration
  def change
    add_column :structured_error_attributes, :match, :boolean
  end
end
