# frozen_string_literal: true

class AddUserTypeToRemoteEvaluationMappings < ActiveRecord::Migration[5.2]
  def change
    add_column :remote_evaluation_mappings, :user_type, :string
    # Update all existing records and set user_type to `ExternalUser` (safe way to prevent any function loss).
    # We are not using a default value here on intend to be in line with the other `user_type` columns
    RemoteEvaluationMapping.update(user_type: 'ExternalUser')
  end
end
