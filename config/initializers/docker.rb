DockerClient.initialize_environment
DockerContainerPool.start_refill_task if DockerContainerPool.config[:active]
at_exit { DockerContainerPool.clean_up } unless Rails.env.test?
