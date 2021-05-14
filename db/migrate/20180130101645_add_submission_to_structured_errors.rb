# frozen_string_literal: true

class AddSubmissionToStructuredErrors < ActiveRecord::Migration[4.2]
  def change
    add_reference :structured_errors, :submission, index: true
  end
end
