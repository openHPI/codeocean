# frozen_string_literal: true

class AddContainerExecutionTimeToTestruns < ActiveRecord::Migration[5.2]
  def change
    add_column :testruns, :container_execution_time, :interval
    add_column :testruns, :waiting_for_container_time, :interval
  end
end
