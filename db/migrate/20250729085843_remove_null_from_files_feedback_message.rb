# frozen_string_literal: true

class RemoveNullFromFilesFeedbackMessage < ActiveRecord::Migration[8.0]
  def up
    CodeOcean::File.where(feedback_message: nil).in_batches.update_all(feedback_message: '') # rubocop:disable Rails/SkipsModelValidations

    change_column_default :files, :feedback_message, ''
    change_column_null :files, :feedback_message, false
  end

  def down
    change_column_null :files, :feedback_message, true
    change_column_default :files, :feedback_message, nil
  end
end
