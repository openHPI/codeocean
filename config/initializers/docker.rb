DockerClient.initialize_environment unless Rails.env.test? && `which docker`.blank?

return if Rake.application.top_level_tasks.to_s.include?('db:')

if ApplicationRecord.connection.tables.present? &&
    DockerContainerPool.config[:active]
  # no op
end
