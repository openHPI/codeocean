require 'concurrent/future'
require 'concurrent/timer_task'


class DockerContainerPool

  @containers = ThreadSafe::Hash[ExecutionEnvironment.all.map { |execution_environment| [execution_environment.id, ThreadSafe::Array.new] }]
  #as containers are not containing containers in use
  @all_containers = ThreadSafe::Hash[ExecutionEnvironment.all.map { |execution_environment| [execution_environment.id, ThreadSafe::Array.new] }]
  def self.clean_up
    @refill_task.try(:shutdown)
    @containers.values.each do |containers|
      DockerClient.destroy_container(containers.shift) until containers.empty?
    end
  end

  def self.config
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)[:pool]
  end

  def self.remove_from_all_containers(container, execution_environment)
    @all_containers[execution_environment.id]-=[container]
    if(@containers[execution_environment.id].include?(container))
      @containers[execution_environment.id]-=[container]
    end
  end

  def self.add_to_all_containers(container, execution_environment)
    @all_containers[execution_environment.id]+=[container]
    if(!@containers[execution_environment.id].include?(container))
      @containers[execution_environment.id]+=[container]
    else
      Rails.logger.info('failed trying to add existing container ' + container.to_s + ' to execution_environment ' + execution_environment.to_s)
    end
  end

  def self.create_container(execution_environment)
    container = DockerClient.create_container(execution_environment)
    container.status = 'available'
    Rails.logger.debug('created container ' + container.to_s + ' for execution environment ' + execution_environment.to_s)
    container
  end

  def self.return_container(container, execution_environment)
    container.status = 'available'
    if(@containers[execution_environment.id] && !@containers[execution_environment.id].include?(container))
      @containers[execution_environment.id].push(container)
    else
      Rails.logger.info('trying to return existing container ' + container.to_s + ' to execution_environment ' + execution_environment.to_s)
    end
  end

  def self.get_container(execution_environment)
    # if pooling is active, do pooling, otherwise just create an container and return it
    if config[:active]
      container = @containers[execution_environment.id].try(:shift) || nil
      Rails.logger.debug('get_container fetched container  ' + container.to_s + ' for execution environment ' + execution_environment.to_s)
      # just access and the following if we got a container. Otherwise, the execution_environment might be just created and not fully exist yet.
      if(container)
        Rails.logger.debug('get_container remaining avail. containers:  ' + @containers[execution_environment.id].size.to_s)
        Rails.logger.debug('get_container all container count: ' + @all_containers[execution_environment.id].size.to_s)
      end
      container
    else
      create_container(execution_environment)
    end
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
    refill_count = [execution_environment.pool_size - @all_containers[execution_environment.id].length, config[:refill][:batch_size]].min
    if refill_count > 0
      Rails.logger.info('Adding ' + refill_count.to_s + ' containers for execution_environment ' +  execution_environment.name )
      c = refill_count.times.map { create_container(execution_environment) }
      Rails.logger.debug('Created containers: ' + c.to_s )
      @containers[execution_environment.id] += c
      @all_containers[execution_environment.id] += c
      Rails.logger.debug('@containers ' + @containers.object_id.to_s + ' has:'+ @containers[execution_environment.id].to_s)
      Rails.logger.debug('@all_containers '  + @containers.object_id.to_s + ' has:'+ @all_containers[execution_environment.id].to_s)
      #refill_count.times.map { create_container(execution_environment) }
    end

  end

  def self.start_refill_task
    @refill_task = Concurrent::TimerTask.new(execution_interval: config[:refill][:interval], run_now: true, timeout_interval: config[:refill][:timeout]) { refill }
    @refill_task.execute
  end
end
