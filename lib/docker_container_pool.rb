require 'concurrent/future'
require 'concurrent/timer_task'
require 'concurrent/utilities'

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

  def self.create_container(execution_environment)
     DockerClient.create_container(execution_environment)
  end

  def self.return_container(container, execution_environment)
    @containers[execution_environment.id].push(container)
  end

  def self.get_container(execution_environment)
    if config[:active]
      @containers[execution_environment.id].try(:shift) || nil
    else
      create_container(execution_environment)
    end
  end

  def self.quantities
    @containers.map { |key, value| [key, value.length] }.to_h
  end

  def self.refill
    ExecutionEnvironment.where('pool_size > 0').each do |execution_environment|
      if config[:refill][:async]
        Concurrent::Future.execute { refill_for_execution_environment(execution_environment) }
      else
        refill_for_execution_environment(execution_environment)
      end
    end
  end

  def self.refill_for_execution_environment(execution_environment)
    refill_count = [execution_environment.pool_size - @all_containers[execution_environment.id].length, config[:refill][:batch_size]].min
    c = refill_count.times.map { create_container(execution_environment) }
    @containers[execution_environment.id] += c
    @all_containers[execution_environment.id] += c
    #refill_count.times.map { create_container(execution_environment) }
  end

  def self.start_refill_task
    @refill_task = Concurrent::TimerTask.new(execution_interval: config[:refill][:interval], run_now: false, timeout_interval: config[:refill][:timeout]) { refill }
    @refill_task.execute
  end
end
