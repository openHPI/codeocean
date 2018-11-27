DockerClient.initialize_environment unless Rails.env.test? && `which docker`.blank?

if !Rake.application.top_level_tasks.to_s.include?('db:') &&
    ApplicationRecord.connection.tables.present? &&
    DockerContainerPool.config[:active]
  DockerContainerPool.start_refill_task
  at_exit { DockerContainerPool.clean_up }
end
