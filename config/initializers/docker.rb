DockerClient.initialize_environment unless Rails.env.test? && `which docker`.blank?

if ActiveRecord::Base.connection.tables.present? && DockerContainerPool.config[:active]
  DockerContainerPool.start_refill_task
  at_exit { DockerContainerPool.clean_up }
end
