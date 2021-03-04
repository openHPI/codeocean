require 'concurrent/future'
require 'concurrent/timer_task'


class DockerContainerPool

  def self.config
    #TODO: Why erb?
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)[:pool]
  end

  def self.create_container(execution_environment)
    Rails.logger.info('trying to create container for execution environment: ' + execution_environment.to_s)
    container = DockerClient.create_container(execution_environment)
    container.status = 'available' # FIXME: String vs Symbol usage?
    #Rails.logger.debug('created container ' + container.to_s + ' for execution environment ' + execution_environment.to_s)
    container
  rescue StandardError => e
    Sentry.set_extras({container: container.inspect, execution_environment: execution_environment.inspect, config: config.inspect})
    Sentry.capture_exception(e)
    nil
  end

  def self.return_container(container, execution_environment)
    Faraday.get(config[:location] + "/docker_container_pool/return_container/" + container.id)
  rescue StandardError => e
    Sentry.set_extras({container: container.inspect, execution_environment: execution_environment.inspect, config: config.inspect})
    Sentry.capture_exception(e)
    nil
  end

  def self.get_container(execution_environment)
    # if pooling is active, do pooling, otherwise just create an container and return it
    if config[:active]
      begin
        container_id = JSON.parse(Faraday.get(config[:location] + "/docker_container_pool/get_container/" + execution_environment.id.to_s).body)['id']
        Docker::Container.get(container_id) unless container_id.blank?
      rescue StandardError => e
        Sentry.set_extras({container_id: container_id.inspect, execution_environment: execution_environment.inspect, config: config.inspect})
        Sentry.capture_exception(e)
        nil
      end
    else
      create_container(execution_environment)
    end
  end

  def self.destroy_container(container)
    Faraday.get(config[:location] + "/docker_container_pool/destroy_container/" + container.id)
  end

  def self.quantities
    response = JSON.parse(Faraday.get(config[:location] + "/docker_container_pool/quantities").body)
    response.transform_keys(&:to_i)
  rescue StandardError => e
    Sentry.set_extras({response: response.inspect})
    Sentry.capture_exception(e)
    []
  end

  def self.dump_info
    JSON.parse(Faraday.get(config[:location] + "/docker_container_pool/dump_info").body)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end
end
