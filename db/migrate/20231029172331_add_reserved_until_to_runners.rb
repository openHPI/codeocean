# frozen_string_literal: true

class AddReservedUntilToRunners < ActiveRecord::Migration[7.1]
  def change
    add_column :runners, :reserved_until, :datetime, null: true, default: nil
  end
end
