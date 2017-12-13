class RemoveExpectedWorkingTime < ActiveRecord::Migration
  def change
    remove_column :exercises, :expected_worktime_seconds
  end
end
