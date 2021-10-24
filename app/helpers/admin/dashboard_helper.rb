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
        []
      end

      ExecutionEnvironment.order(:id).select(:id, :pool_size).map do |execution_environment|
        execution_environment.attributes.merge(quantity: pool_size[execution_environment.id])
      end
    end
  end
end
