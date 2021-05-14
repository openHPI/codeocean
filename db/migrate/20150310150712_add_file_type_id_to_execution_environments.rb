# frozen_string_literal: true

class AddFileTypeIdToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_reference :execution_environments, :file_type
  end
end
