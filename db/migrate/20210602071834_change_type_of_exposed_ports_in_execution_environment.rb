# frozen_string_literal: true

class ChangeTypeOfExposedPortsInExecutionEnvironment < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/SkipsModelValidations:
  def up
    rename_column :execution_environments, :exposed_ports, :exposed_ports_migration
    add_column :execution_environments, :exposed_ports, :integer, array: true, default: [], nil: true

    ExecutionEnvironment.all.each do |execution_environment|
      next if execution_environment.exposed_ports_migration.nil?

      cleaned = execution_environment.exposed_ports_migration.scan(/\d+/)
      list = cleaned.map(&:to_i).uniq.sort
      execution_environment.update_columns(exposed_ports: list)
    end

    remove_column :execution_environments, :exposed_ports_migration
  end

  def down
    rename_column :execution_environments, :exposed_ports, :exposed_ports_migration
    add_column :execution_environments, :exposed_ports, :string

    ExecutionEnvironment.all.each do |execution_environment|
      next if execution_environment.exposed_ports_migration.empty?

      list = execution_environment.exposed_ports_migration
      if list.empty?
        execution_environment.update_columns(exposed_ports: nil)
      else
        execution_environment.update_columns(exposed_ports: list.join(','))
      end
    end
    remove_column :execution_environments, :exposed_ports_migration
  end
  # rubocop:enable Rails/SkipsModelValidations:
end
