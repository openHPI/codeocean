# frozen_string_literal: true

module DockerContainerMixin
  attr_accessor :start_time, :status, :execution_environment, :docker_client

  def binds
    host_config['Binds']
  end

  def port_bindings
    # Don't use cached version as this might be changed during runtime
    json['HostConfig']['PortBindings'].try(:map) {|key, value| [key.to_i, value.first['HostPort'].to_i] }.to_h
  end

  def host_config
    @host_config ||= json['HostConfig']
  end
end
