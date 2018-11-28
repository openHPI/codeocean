class AddFileTemplateToFile < ActiveRecord::Migration[4.2]
  def change
    add_reference :files, :file_template
  end
end
