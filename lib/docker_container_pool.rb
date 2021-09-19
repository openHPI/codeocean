# frozen_string_literal: true

require 'concurrent/future'
require 'concurrent/timer_task'

# get_container, destroy_container was moved to lib/runner/strategy/docker_container_pool.rb.
# return_container is not used anymore because runners are not shared between users anymore.
# create_container is done by the DockerContainerPool.
# dump_info and quantities are still in use.

class DockerContainerPool
  def self.active?
    # TODO: Refactor config and merge with code_ocean.yml
    config[:active] && Runner.management_active? && Runner.strategy_class == Runner::Strategy::DockerContainerPool
  end

  def self.config
    # TODO: Why erb?
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)[:pool]
  end

  def self.create_container(execution_environment)
    Rails.logger.info("trying to create container for execution environment: #{execution_environment}")
    container = DockerClient.create_container(execution_environment)
    container.status = 'available' # FIXME: String vs Symbol usage?
    # Rails.logger.debug('created container ' + container.to_s + ' for execution environment ' + execution_environment.to_s)
    container
  rescue StandardError => e
    Sentry.set_extras({container: container.inspect, execution_environment: execution_environment.inspect,
      config: config.inspect})
    Sentry.capture_exception(e)
    nil
  end

  # not in use because DockerClient::RECYCLE_CONTAINERS == false
  def self.return_container(container, execution_environment)
    Faraday.get("#{config[:location]}/docker_container_pool/return_container/#{container.id}")
  rescue StandardError => e
    Sentry.set_extras({container: container.inspect, execution_environment: execution_environment.inspect,
      config: config.inspect})
    Sentry.capture_exception(e)
    nil
  end

  def self.get_container(execution_environment)
    # if pooling is active, do pooling, otherwise just create an container and return it
    if active?
      begin
        container_id = JSON.parse(Faraday.get("#{config[:location]}/docker_container_pool/get_container/#{execution_environment.id}").body)['id']
        Docker::Container.get(container_id) if container_id.present?
      rescue StandardError => e
        Sentry.set_extras({container_id: container_id.inspect, execution_environment: execution_environment.inspect,
          config: config.inspect})
        Sentry.capture_exception(e)
        nil
      end
    else
      create_container(execution_environment)
    end
  end

  def self.destroy_container(container)
    Faraday.get("#{config[:location]}/docker_container_pool/destroy_container/#{container.id}")
  end

  def self.quantities
    response = JSON.parse(Faraday.get("#{config[:location]}/docker_container_pool/quantities").body)
    response.transform_keys(&:to_i)
  rescue StandardError => e
    Sentry.set_extras({response: response.inspect})
    Sentry.capture_exception(e)
    []
  end

  def self.dump_info
    JSON.parse(Faraday.get("#{config[:location]}/docker_container_pool/dump_info").body)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end
end
