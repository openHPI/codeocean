require 'concurrent/future'
require 'concurrent/timer_task'


class DockerContainerPool

  # Always use a semaphore when dealing with write access to `@containers` or `@all_containers` or read access if that involves creating a new container
  # Some methods have the `bypass_semaphore` flag which should be rarely used. It was introduced when adding the semaphore to the `replace_broken_container` method.
  # When `replace_broken_container` was extended to check the total amount of containers first, the `bypass_semaphore` flag was also added to `get_container` and
  # back to `replace_broken_container`. When the semaphore is not released, no container operations can be done!
  # Furthermore, the semaphore is used when killing a container in the DockerClient.
  @semaphore = Concurrent::Semaphore.new(1)

  @containers = Concurrent::Hash[ExecutionEnvironment.all.map { |execution_environment| [execution_environment.id, Concurrent::Array.new] }]
  #as containers are not containing containers in use
  @all_containers = Concurrent::Hash[ExecutionEnvironment.all.map { |execution_environment| [execution_environment.id, Concurrent::Array.new] }]

  def self.clean_up
    Rails.logger.info('Container Pool is now performing a cleanup. ')
    @refill_task.try(:shutdown)
    @all_containers.values.each do |containers|
      DockerClient.destroy_container(containers.shift) until containers.empty?
    end
  end

  def self.config
    #TODO: Why erb?
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)[:pool]
  end

  def self.containers
    @containers
  end

  def self.all_containers
    @all_containers
  end

  def self.acquire_semaphore
    Rails.logger.info("Semaphore - Acquire: Trying " + @semaphore.inspect.to_s + " for " + caller_locations(1, 1)[0].label)
    got_semaphore = @semaphore.try_acquire(1, 20)
    if got_semaphore
      Rails.logger.info("Semaphore - Acquire: Got " + @semaphore.inspect.to_s + " for " + caller_locations(1, 1)[0].label)
    else
      Rails.logger.error("Semaphore - Acquire: Failed " + @semaphore.inspect.to_s + " for " + caller_locations(1, 1)[0].label)
    end
  end

  def self.release_semaphore
    Rails.logger.info("Semaphore - Release: Trying " + @semaphore.inspect.to_s + " for " + caller_locations(1, 1)[0].label)
    if @semaphore.available_permits < 1
      @semaphore.release
      Rails.logger.info("Semaphore - Release: Done " + @semaphore.inspect.to_s + " for " + caller_locations(1, 1)[0].label)
    else
      Rails.logger.info("Semaphore - Release: Failed " + @semaphore.inspect.to_s + " for " + caller_locations(1, 1)[0].label)
    end
  end

  def self.remove_from_all_containers(container, execution_environment)
    if @containers[execution_environment.id].include?(container)
      @containers[execution_environment.id].delete(container)
      Rails.logger.debug('Removed container ' + container.to_s + ' from available_pool for execution environment ' + execution_environment.to_s + '. Remaining containers in available_pool ' + @containers[execution_environment.id].size.to_s)
    end

    @all_containers[execution_environment.id].delete(container)
    Rails.logger.debug('Removed container ' + container.to_s + ' from all_pool for execution environment ' + execution_environment.to_s + '. Remaining containers in all_pool ' + @all_containers[execution_environment.id].size.to_s)
  end

  def self.add_to_all_containers(container, execution_environment)
    @all_containers[execution_environment.id].push(container)
    if !@containers[execution_environment.id].include?(container)
      @containers[execution_environment.id].push(container)
      #Rails.logger.debug('Added container ' + container.to_s + ' to all_pool for execution environment ' + execution_environment.to_s + '. Containers in all_pool: ' + @all_containers[execution_environment.id].size.to_s)
    else
      Rails.logger.error('failed trying to add existing container ' + container.to_s + ' to execution_environment ' + execution_environment.to_s)
    end
  end

  def self.create_container(execution_environment)
    Rails.logger.info('trying to create container for execution environment: ' + execution_environment.to_s)
    container = DockerClient.create_container(execution_environment)
    container.status = 'available' # FIXME: String vs Symbol usage?
    #Rails.logger.debug('created container ' + container.to_s + ' for execution environment ' + execution_environment.to_s)
    container
  end

  def self.return_container(container, execution_environment)
    container.status = 'available' # FIXME: String vs Symbol usage?
    if @containers[execution_environment.id] && !@containers[execution_environment.id].include?(container)
      @containers[execution_environment.id].push(container)
    else
      Rails.logger.error('trying to return existing container ' + container.to_s + ' to execution_environment ' + execution_environment.to_s)
    end
  end

  def self.get_container(execution_environment, bypass_semaphore: false)
    # if pooling is active, do pooling, otherwise just create an container and return it
    if config[:active]
      container = @containers[execution_environment.id].try(:shift) || nil
      Rails.logger.debug('get_container fetched container  ' + container.to_s + ' for execution environment ' + execution_environment.to_s)
      # just access and the following if we got a container. Otherwise, the execution_environment might be just created and not fully exist yet.
      if(container)
        begin
          # check whether the container is running. exited containers go to the else part.
          # Dead containers raise a NotFOundError on the container.json call. This is handled in the rescue block.
          if(container.json['State']['Running'])
            Rails.logger.debug('get_container remaining avail. containers:  ' + @containers[execution_environment.id].size.to_s)
            Rails.logger.debug('get_container all container count: ' + @all_containers[execution_environment.id].size.to_s)
          else
            Rails.logger.error('docker_container_pool.get_container retrieved a container not running. Container will be removed from list:  ' + container.to_s)
            #TODO: check in which state the container actually is and treat it accordingly (dead,... => destroy?)
            container = replace_broken_container(container, execution_environment, bypass_semaphore: bypass_semaphore)
          end
        rescue Docker::Error::NotFoundError => error
          Rails.logger.error('docker_container_pool.get_container rescued from Docker::Error::NotFoundError. Most likely, the container is not there any longer. Removing faulty entry from list: ' + container.to_s)
          container = replace_broken_container(container, execution_environment, bypass_semaphore: bypass_semaphore)
        end
      end
      # returning nil is no problem. then the pool is just depleted.
      container
    else
      create_container(execution_environment)
    end
  end

  def self.replace_broken_container(container, execution_environment, bypass_semaphore: false)
    # See note at the top for `bypass_semaphore`
    acquire_semaphore unless bypass_semaphore
    remove_from_all_containers(container, execution_environment)
    missing_counter_count = execution_environment.pool_size - @all_containers[execution_environment.id].length
    if missing_counter_count > 0
      Rails.logger.error('replace_broken_container: Creating a new container and returning that.')
      new_container = create_container(execution_environment)
      DockerContainerPool.add_to_all_containers(new_container, execution_environment)
    else
      Rails.logger.error('Broken container removed for ' + execution_environment.to_s + ' but not creating a new one. Currently, ' + missing_counter_count.abs + ' more containers than the configured pool size are available.')
      new_container = get_container(execution_environment, bypass_semaphore: true)
    end
    release_semaphore unless bypass_semaphore
    new_container
  end

  def self.quantities
    @containers.map { |key, value| [key, value.length] }.to_h
  end

  def self.refill
    ExecutionEnvironment.where('pool_size > 0').order(pool_size: :desc).each do |execution_environment|
      if config[:refill][:async]
        Concurrent::Future.execute { refill_for_execution_environment(execution_environment) }
      else
        refill_for_execution_environment(execution_environment)
      end
    end
  end

  def self.refill_for_execution_environment(execution_environment)
    acquire_semaphore
    refill_count = [execution_environment.pool_size - @all_containers[execution_environment.id].length, config[:refill][:batch_size]].min
    if refill_count > 0
      Rails.logger.info('Adding ' + refill_count.to_s + ' containers for execution_environment ' + execution_environment.name )
      multiple_containers = refill_count.times.map { create_container(execution_environment) }
      #Rails.logger.info('Created containers: ' + multiple_containers.to_s )
      @containers[execution_environment.id].concat(multiple_containers)
      @all_containers[execution_environment.id].concat(multiple_containers)
      #Rails.logger.debug('@containers  for ' + execution_environment.name.to_s + ' (' + @containers.object_id.to_s + ') has the following content: '+ @containers[execution_environment.id].to_s)
      #Rails.logger.debug('@all_containers for '  + execution_environment.name.to_s + ' (' + @all_containers.object_id.to_s + ') has the following content: ' + @all_containers[execution_environment.id].to_s)
    end
    release_semaphore
  end

  def self.start_refill_task
    @refill_task = Concurrent::TimerTask.new(execution_interval: config[:refill][:interval], run_now: true, timeout_interval: config[:refill][:timeout]) { refill }
    @refill_task.execute
  end
end
