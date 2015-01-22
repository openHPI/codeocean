class AddFeedbackMessageToFiles < ActiveRecord::Migration
  def change
    add_column :files, :feedback_message, :string
  end
end
