require 'concurrent'

class DockerClient
  CONTAINER_WORKSPACE_PATH = '/workspace'
  LOCAL_WORKSPACE_ROOT = Rails.root.join('tmp', 'files', Rails.env)

  attr_reader :assigned_ports
  attr_reader :container_id

  def self.check_availability!
    Timeout::timeout(config[:connection_timeout]) { Docker.version }
  rescue Excon::Errors::SocketError, Timeout::Error
    raise Error.new("The Docker host at #{Docker.url} is not reachable!")
  end

  def command_substitutions(filename)
    {class_name: File.basename(filename, File.extname(filename)).camelize, filename: filename}
  end
  private :command_substitutions

  def self.config
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)
  end

  def copy_file_to_workspace(options = {})
    FileUtils.cp(options[:file].native_file.path, local_file_path(options))
  end

  def self.create_container(execution_environment)
    container = Docker::Container.create('Image' => find_image_by_tag(execution_environment.docker_image).info['RepoTags'].first, 'OpenStdin' => true, 'StdinOnce' => true)
    local_workspace_path = generate_local_workspace_path
    FileUtils.mkdir(local_workspace_path)
    container.start('Binds' => mapped_directories(local_workspace_path), 'PortBindings' => mapped_ports(execution_environment))
    container
  end

  def create_workspace(container)
    @submission.collect_files.each do |file|
      FileUtils.mkdir_p(File.join(self.class.local_workspace_path(container), file.path || ''))
      if file.file_type.binary?
        copy_file_to_workspace(container: container, file: file)
      else
        create_workspace_file(container: container, file: file)
      end
    end
  end
  private :create_workspace

  def create_workspace_file(options = {})
    file = File.new(local_file_path(options), 'w')
    file.write(options[:file].content)
    file.close
  end
  private :create_workspace_file

  def self.destroy_container(container)
    container.stop.kill
    (container.port_bindings.try(:values) || []).each do |configuration|
      port = configuration.first['HostPort'].to_i
      PortPool.release(port)
    end
    FileUtils.rm_rf(local_workspace_path(container))
    container.delete(force: true)
  end

  def execute_arbitrary_command(command, &block)
    container = DockerContainerPool.get_container(@execution_environment)
    @container_id = container.id
    send_command(command, container, &block)
  end

  [:run, :test].each do |cause|
    define_method("execute_#{cause}_command") do |submission, filename, &block|
      container = DockerContainerPool.get_container(submission.execution_environment)
      @container_id = container.id
      @submission = submission
      create_workspace(container)
      command = submission.execution_environment.send(:"#{cause}_command") % command_substitutions(filename)
      send_command(command, container, &block)
    end
  end

  def self.find_image_by_tag(tag)
    Docker::Image.all.detect { |image| image.info['RepoTags'].flatten.include?(tag) }
  end

  def self.generate_local_workspace_path
    File.join(LOCAL_WORKSPACE_ROOT, SecureRandom.uuid)
  end

  def self.image_tags
    Docker::Image.all.map { |image| image.info['RepoTags'] }.flatten.reject { |tag| tag.include?('<none>') }
  end

  def initialize(options = {})
    @execution_environment = options[:execution_environment]
    @user = options[:user]
    @image = self.class.find_image_by_tag(@execution_environment.docker_image)
    raise Error.new("Cannot find image #{@execution_environment.docker_image}!") unless @image
  end

  def self.initialize_environment
    unless config[:connection_timeout] && config[:workspace_root]
      raise Error.new('Docker configuration missing!')
    end
    Docker.url = config[:host] if config[:host]
    check_availability!
    FileUtils.mkdir_p(LOCAL_WORKSPACE_ROOT)
  end

  def local_file_path(options = {})
    File.join(self.class.local_workspace_path(options[:container]), options[:file].path || '', options[:file].name_with_extension)
  end
  private :local_file_path

  def self.local_workspace_path(container)
    Pathname.new(container.binds.first.split(':').first.sub(config[:workspace_root], LOCAL_WORKSPACE_ROOT.to_s))
  end

  def self.mapped_directories(local_workspace_path)
    remote_workspace_path = local_workspace_path.sub(LOCAL_WORKSPACE_ROOT.to_s, config[:workspace_root])
    ["#{remote_workspace_path}:#{CONTAINER_WORKSPACE_PATH}"]
  end

  def self.mapped_ports(execution_environment)
    (execution_environment.exposed_ports || '').gsub(/\s/, '').split(',').map do |port|
      ["#{port}/tcp", [{'HostPort' => PortPool.available_port.to_s}]]
    end.to_h
  end

  def self.pull(docker_image)
    `docker pull #{docker_image}` if docker_image
  end

  def send_command(command, container, &block)
    Timeout::timeout(@execution_environment.permitted_execution_time) do
      stderr = []
      stdout = []
      container.attach(stdin: StringIO.new(command)) do |stream, chunk|
        block.call(stream, chunk) if block_given?
        if stream == :stderr
          stderr.push(chunk)
        else
          stdout.push(chunk)
        end
      end
      {status: :ok, stderr: stderr.join, stdout: stdout.join}
    end
  rescue Timeout::Error
    {status: :timeout}
  ensure
    Concurrent::Future.execute { self.class.destroy_container(container) }
  end
  private :send_command
end

class DockerClient::Error < RuntimeError
end
