# frozen_string_literal: true

class AddSubmissionToError < ActiveRecord::Migration[4.2]
  def change
    add_reference :errors, :submission, index: true
  end
end
