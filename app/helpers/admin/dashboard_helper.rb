# frozen_string_literal: true

module Admin
  module DashboardHelper
    def dashboard_data
      {docker: docker_data}
    end

    def docker_data
      pool_size = begin
        Runner.strategy_class.pool_size
      rescue Runner::Error => e
        Rails.logger.debug { "Runner error while fetching current pool size: #{e.message}" }
        {}
      end

      ExecutionEnvironment.order(:id).select(:id, :pool_size).map do |execution_environment|
        # Fetch the actual values (ID is stored as a symbol) or get an empty hash for merge
        actual = pool_size[execution_environment.id.to_s.to_sym] || {}

        template = {
          id: execution_environment.id,
          prewarmingPoolSize: execution_environment.pool_size,
          idleRunners: 0,
          usedRunners: 0,
        }

        # Existing values in the template get replaced with actual values
        template.merge(actual)
      end
    end

    def self.runner_management_release
      Runner.strategy_class.release
    rescue Runner::Error => e
      e.inspect
    end
  end
end
