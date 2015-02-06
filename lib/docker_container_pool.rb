require 'concurrent/future'
require 'concurrent/timer_task'
require 'concurrent/utilities'

class DockerContainerPool
  @containers = ThreadSafe::Hash[ExecutionEnvironment.all.map { |execution_environment| [execution_environment.id, ThreadSafe::Array.new] }]

  def self.clean_up
    @refill_task.try(:shutdown)
    @containers.each do |key, value|
      while !value.empty? do
        DockerClient.destroy_container(value.shift)
      end
    end
  end

  def self.config
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)[:pool]
  end

  def self.create_container(execution_environment)
    DockerClient.create_container(execution_environment)
  end

  def self.get_container(execution_environment)
    if config[:active]
      @containers[execution_environment.id].try(:shift) || create_container(execution_environment)
    else
      create_container(execution_environment)
    end
  end

  def self.quantities
    @containers.map { |key, value| [key, value.length] }.to_h
  end

  def self.refill
    ExecutionEnvironment.all.each do |execution_environment|
      refill_count = execution_environment.pool_size - @containers[execution_environment.id].length
      if refill_count > 0
        Concurrent::Future.execute do
          @containers[execution_environment.id] += refill_count.times.map { create_container(execution_environment) }
        end
      end
    end
  end

  def self.start_refill_task
    @refill_task = Concurrent::TimerTask.new(execution_interval: config[:interval], run_now: true) { refill }
    @refill_task.execute
  end
end
