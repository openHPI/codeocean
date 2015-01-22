class PortPool
  PORT_RANGE = DockerClient.config[:ports]

  @available_ports = PORT_RANGE.to_a
  @mutex = Mutex.new

  def self.available_port
    @mutex.synchronize do
      @available_ports.delete(@available_ports.sample)
    end
  end

  def self.release(port)
    @available_ports << port if PORT_RANGE.include?(port) && !@available_ports.include?(port)
  end
end
