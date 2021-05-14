# frozen_string_literal: true

class RemoveExpectedWorkingTime < ActiveRecord::Migration[4.2]
  def change
    remove_column :exercises, :expected_worktime_seconds
  end
end
