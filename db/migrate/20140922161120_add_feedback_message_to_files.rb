class AddFeedbackMessageToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :feedback_message, :string
  end
end
