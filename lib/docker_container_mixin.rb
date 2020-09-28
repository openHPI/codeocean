module DockerContainerMixin

  attr_accessor :start_time
  attr_accessor :status
  attr_accessor :re_use
  attr_accessor :execution_environment
  attr_accessor :docker_client

  def binds
    json['HostConfig']['Binds']
  end

  def port_bindings
    json['HostConfig']['PortBindings'].try(:map) { |key, value| [key.to_i, value.first['HostPort'].to_i] }.to_h
  end
end
