module Admin
  module DashboardHelper
    def dashboard_data
      {docker: docker_data}
    end

    def docker_data
      ExecutionEnvironment.order(:id).select(:id, :pool_size).map do |execution_environment|
        execution_environment.attributes.merge(quantity: DockerContainerPool.quantities[execution_environment.id])
      end
    end
  end
end
