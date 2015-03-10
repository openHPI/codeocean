class AddFileTypeIdToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_reference :execution_environments, :file_type
  end
end
