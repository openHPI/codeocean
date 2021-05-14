# frozen_string_literal: true

class ChangeCommentTextAttributeToTextDatatype < ActiveRecord::Migration[4.2]
  def up
    change_column :comments, :text, :text
  end

  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :comments, :text, :string
  end
end
