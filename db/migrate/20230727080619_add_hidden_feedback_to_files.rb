# frozen_string_literal: true

class AddHiddenFeedbackToFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :files, :hidden_feedback, :boolean, default: false, null: false
  end
end
