class DockerClient
  CONFIG_PATH = Rails.root.join('config', 'docker.yml.erb')
  CONTAINER_WORKSPACE_PATH = '/workspace'
  LOCAL_WORKSPACE_ROOT = Rails.root.join('tmp', 'files', Rails.env)

  attr_reader :assigned_ports
  attr_reader :container_id

  def bound_folders
    @submission ? ["#{remote_workspace_path}:#{CONTAINER_WORKSPACE_PATH}"] : []
  end
  private :bound_folders

  def self.check_availability!
    initialize_environment
    Timeout::timeout(config[:connection_timeout]) { Docker.version }
  rescue Excon::Errors::SocketError, Timeout::Error
    raise Error.new("The Docker host at #{Docker.url} is not reachable!")
  end

  def clean_workspace
    FileUtils.rm_rf(local_workspace_path)
  end
  private :clean_workspace

  def command_substitutions(filename)
    {class_name: File.basename(filename, File.extname(filename)).camelize, filename: filename}
  end
  private :command_substitutions

  def self.config
    YAML.load(ERB.new(File.new(CONFIG_PATH, 'r').read).result)[Rails.env].with_indifferent_access
  end

  def copy_file_to_workspace(options = {})
    FileUtils.cp(options[:file].native_file.path, File.join(local_workspace_path, options[:file].path || '', options[:file].name_with_extension))
  end

  def create_container(options = {})
    Docker::Container.create('Cmd' => options[:command], 'Image' => @image.info['RepoTags'].first)
  end
  private :create_container

  def create_workspace
    @submission.collect_files.each do |file|
      FileUtils.mkdir_p(File.join(local_workspace_path, file.path || ''))
      if file.file_type.binary?
        copy_file_to_workspace(file: file)
      else
        create_workspace_file(file: file)
      end
    end
  end
  private :create_workspace

  def create_workspace_file(options = {})
    file = File.new(File.join(local_workspace_path, options[:file].path || '', options[:file].name_with_extension), 'w')
    file.write(options[:file].content)
    file.close
  end
  private :create_workspace_file

  def self.destroy_container(container)
    container.stop.kill
    if container.json['HostConfig']['PortBindings']
      container.json['HostConfig']['PortBindings'].values.each do |configuration|
        port = configuration.first['HostPort'].to_i
        PortPool.release(port)
      end
    end
  end

  def execute_command(command, &block)
    container = create_container(command: ['bash', '-c', command])
    @container_id = container.id
    start_container(container, &block)
  end

  def execute_in_workspace(submission, &block)
    @submission = submission
    create_workspace
    block.call
  ensure
    clean_workspace if @submission
  end
  private :execute_in_workspace

  def execute_run_command(submission, filename, &block)
    execute_in_workspace(submission) do
      execute_command(@execution_environment.run_command % command_substitutions(filename), &block)
    end
  end

  def execute_test_command(submission, filename)
    execute_in_workspace(submission) do
      execute_command(@execution_environment.test_command % command_substitutions(filename))
    end
  end

  def find_image_by_tag(tag)
    Docker::Image.all.detect { |image| image.info['RepoTags'].flatten.include?(tag) }
  end
  private :find_image_by_tag

  def self.image_tags
    check_availability!
    Docker::Image.all.map { |image| image.info['RepoTags'] }.flatten.reject { |tag| tag.include?('<none>') }
  end

  def initialize(options = {})
    self.class.check_availability!
    @execution_environment = options[:execution_environment]
    @user = options[:user]
    @image = find_image_by_tag(@execution_environment.docker_image)
    raise Error.new("Cannot find image #{@execution_environment.docker_image}!") unless @image
  end

  def self.initialize_environment
    unless config[:connection_timeout] && config[:workspace_root]
      raise Error.new('Docker configuration missing!')
    end
    Docker.url = config[:host] if config[:host]
  end

  def local_workspace_path
    File.join(LOCAL_WORKSPACE_ROOT, @submission.id.to_s)
  end
  private :local_workspace_path

  def mapped_ports
    @assigned_ports = []
    (@execution_environment.exposed_ports || '').gsub(/\s/, '').split(',').map do |port|
      @assigned_ports << PortPool.available_port
      ["#{port}/tcp", [{'HostPort' => @assigned_ports.last.to_s}]]
    end.to_h
  end
  private :mapped_ports

  def self.pull(docker_image)
    `docker pull #{docker_image}` if docker_image
  end

  def remote_workspace_path
    File.join(self.class.config[:workspace_root], @submission.id.to_s)
  end
  private :remote_workspace_path

  def start_container(container, &block)
    Timeout::timeout(@execution_environment.permitted_execution_time) do
      container.start('Binds' => bound_folders, 'PortBindings' => mapped_ports)
      container.wait(@execution_environment.permitted_execution_time)
      stderr = []
      stdout = []
      container.streaming_logs(stderr: true, stdout: true) do |stream, chunk|
        block.call(stream, chunk) if block_given?
        if stream == :stderr
          stderr.push(chunk)
        else
          stdout.push(chunk)
        end
      end
      {status: :ok, stderr: stderr.join, stdout: stdout.join}
    end
  rescue Docker::Error::TimeoutError, Timeout::Error
    {status: :timeout}
  ensure
    self.class.destroy_container(container)
  end
  private :start_container
end

class DockerClient::Error < RuntimeError
end

DockerClient.initialize_environment
