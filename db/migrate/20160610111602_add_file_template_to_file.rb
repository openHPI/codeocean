class AddFileTemplateToFile < ActiveRecord::Migration
  def change
    add_reference :files, :file_template
  end
end
