# frozen_string_literal: true

class CleanExposedPortsInExecutionEnvironment < ActiveRecord::Migration[6.1]
  def change
    ExecutionEnvironment.all.each do |execution_environment|
      next if execution_environment.exposed_ports.nil?

      cleaned = execution_environment.exposed_ports.gsub(/[[:space:]]/, '')
      list = cleaned.split(',').map(&:to_i).uniq
      if list.empty?
        execution_environment.update(exposed_ports: nil)
      else
        execution_environment.update(exposed_ports: list.join(','))
      end
    end
  end
end
