module DockerContainerMixin
  def binds
    json['HostConfig']['Binds']
  end

  def port_bindings
    json['HostConfig']['PortBindings']
  end
end
