require 'concurrent'
require 'pathname'

class DockerClient
  CONTAINER_WORKSPACE_PATH = '/workspace'
  DEFAULT_MEMORY_LIMIT = 256
  # Ralf: I suggest to replace this with the environment variable. Ask Hauke why this is not the case!
  LOCAL_WORKSPACE_ROOT = Rails.root.join('tmp', 'files', Rails.env)
  MINIMUM_MEMORY_LIMIT = 4
  RECYCLE_CONTAINERS = true
  RETRY_COUNT = 2

  attr_reader :container
  attr_reader :socket
  attr_accessor :tubesock

  def self.check_availability!
    Timeout.timeout(config[:connection_timeout]) { Docker.version }
  rescue Excon::Errors::SocketError, Timeout::Error
    raise(Error, "The Docker host at #{Docker.url} is not reachable!")
  end

  def self.clean_container_workspace(container)
    local_workspace_path = local_workspace_path(container)
    if local_workspace_path &&  Pathname.new(local_workspace_path).exist?
      Pathname.new(local_workspace_path).children.each{ |p| p.rmtree}
      #FileUtils.rmdir(Pathname.new(local_workspace_path))
    end
  end

  def command_substitutions(filename)
    {class_name: File.basename(filename, File.extname(filename)).camelize, filename: filename, module_name: File.basename(filename, File.extname(filename)).underscore}
  end
  private :command_substitutions

  def self.config
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)
  end

  def self.container_creation_options(execution_environment)
    {
      'Image' => find_image_by_tag(execution_environment.docker_image).info['RepoTags'].first,
      'Memory' => execution_environment.memory_limit.megabytes,
      'NetworkDisabled' => !execution_environment.network_enabled?,
      'OpenStdin' => true,
      'StdinOnce' => true,
      # required to expose standard streams over websocket
      'AttachStdout' => true,
      'AttachStdin' => true,
      'AttachStderr' => true,
      'Tty' => true
    }
  end

  def self.container_start_options(execution_environment, local_workspace_path)
    {
      'Binds' => mapped_directories(local_workspace_path),
      'PortBindings' => mapped_ports(execution_environment)
    }
  end

  def create_socket(container, stderr=false)
    # todo factor out query params
    # todo separate stderr
    query_params = 'logs=0&stream=1&' + (stderr ? 'stderr=1' : 'stdout=1&stdin=1')

    # Headers are required by Docker
    headers = {'Origin' => 'http://localhost'}

    socket = Faye::WebSocket::Client.new(DockerClient.config['ws_host'] + '/containers/' + @container.id + '/attach/ws?' + query_params, [], :headers => headers)

    socket.on :error do |event|
      Rails.logger.info "Websocket error: " + event.message
    end
    socket.on :close do |event|
      Rails.logger.info "Websocket closed."
    end
    socket.on :open do |event|
      Rails.logger.info "Websocket created."
      kill_after_timeout(container)
    end
    socket
  end

  def copy_file_to_workspace(options = {})
    FileUtils.cp(options[:file].native_file.path, local_file_path(options))
  end

  def self.create_container(execution_environment)
    tries ||= 0
    container = Docker::Container.create(container_creation_options(execution_environment))
    local_workspace_path = generate_local_workspace_path
    # container.start always creates the passed local_workspace_path on disk. Seems like we have to live with that, therefore we can also just create the empty folder ourselves.
    FileUtils.mkdir(local_workspace_path)
    container.start(container_start_options(execution_environment, local_workspace_path))
    container.start_time = Time.now
    container.status = :created
    container
  rescue Docker::Error::NotFoundError => error
    Rails.logger.info('create_container: Got Docker::Error::NotFoundError: ' + error)
    destroy_container(container)
    #(tries += 1) <= RETRY_COUNT ? retry : raise(error)
  end

  def create_workspace_files(container, submission)
    #clear directory (it should be empty anyhow)
    #Pathname.new(self.class.local_workspace_path(container)).children.each{ |p| p.rmtree}
    submission.collect_files.each do |file|
      FileUtils.mkdir_p(File.join(self.class.local_workspace_path(container), file.path || ''))
      if file.file_type.binary?
        copy_file_to_workspace(container: container, file: file)
      else
        create_workspace_file(container: container, file: file)
      end
    end
  end
  private :create_workspace_files

  def create_workspace_file(options = {})
    file = File.new(local_file_path(options), 'w')
    file.write(options[:file].content)
    file.close
  end
  private :create_workspace_file

  def self.destroy_container(container)
    Rails.logger.info('destroying container ' + container.to_s)
    container.stop.kill
    container.port_bindings.values.each { |port| PortPool.release(port) }
    clean_container_workspace(container)
    if(container)
      container.delete(force: true, v: true)
    end
  end

  def execute_arbitrary_command(command, &block)
    execute_command(command, nil, block)
  end

  def execute_command(command, before_execution_block, output_consuming_block)
    #tries ||= 0
    @container = DockerContainerPool.get_container(@execution_environment)
    if @container
      @container.status = :executing
      before_execution_block.try(:call)
      send_command(command, @container, &output_consuming_block)
    else
      {status: :container_depleted}
    end
  rescue Excon::Errors::SocketError => error
    # socket errors seems to be normal when using exec
    # so lets ignore them for now
    #(tries += 1) <= RETRY_COUNT ? retry : raise(error)
  end

  def execute_websocket_command(command, before_execution_block, output_consuming_block)
    @container = DockerContainerPool.get_container(@execution_environment)
    if @container
      @container.status = :executing
      before_execution_block.try(:call)
      # todo catch exception if socket could not be created
      @socket ||= create_socket(@container)
      # Newline required to flush
      @socket.send command + "\n"
      {status: :container_running, socket: @socket, container: @container}
    else
      {status: :container_depleted}
    end
  end

  def kill_after_timeout(container)
    """
    We need to start a second thread to kill the websocket connection,
    as it is impossible to determine whether further input is requested.
    """
    @thread = Thread.new do
      begin
        timeout = @execution_environment.permitted_execution_time.to_i # seconds
        sleep(timeout)
        if container.status != :returned
          Rails.logger.info('Killing container after timeout of ' + timeout.to_s + ' seconds.')
          # send timeout to the tubesock socket
          if(@tubesock)
            @tubesock.send_data JSON.dump({'cmd' => 'timeout'})
          end
          kill_container(container)
        end
      ensure
        #guarantee that the thread is releasing the DB connection after it is done
        ActiveRecord::Base.connectionpool.releaseconnection
      end
    end
  end

  def exit_container(container)
    Rails.logger.debug('exiting container ' + container.to_s)
    # exit the timeout thread if it is still alive
    if(@thread && @thread.alive?)
      @thread.exit
    end
    # if we use pooling and recylce the containers, put it back. otherwise, destroy it.
    (DockerContainerPool.config[:active] && RECYCLE_CONTAINERS) ? self.class.return_container(container, @execution_environment) : self.class.destroy_container(container)
  end

  def kill_container(container)
    Rails.logger.info('killing container ' + container.to_s)
    # remove container from pool, then destroy it
    if (DockerContainerPool.config[:active])
      DockerContainerPool.remove_from_all_containers(container, @execution_environment)
    end

    self.class.destroy_container(container)

    # if we recylce containers, we start a fresh one
    if(DockerContainerPool.config[:active] && RECYCLE_CONTAINERS)
      # create new container and add it to @all_containers and @containers.
      container = self.class.create_container(@execution_environment)
      DockerContainerPool.add_to_all_containers(container, @execution_environment)
    end
  end

  def execute_run_command(submission, filename, &block)
    """
    Run commands by attaching a websocket to Docker.
    """
    command = submission.execution_environment.run_command % command_substitutions(filename)
    create_workspace_files = proc { create_workspace_files(container, submission) }
    execute_websocket_command(command, create_workspace_files, block)
  end

  def execute_test_command(submission, filename, &block)
    """
    Stick to existing Docker API with exec command.
    """
    command = submission.execution_environment.test_command % command_substitutions(filename)
    create_workspace_files = proc { create_workspace_files(container, submission) }
    execute_command(command, create_workspace_files, block)
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
    @image = self.class.find_image_by_tag(@execution_environment.docker_image)
    fail(Error, "Cannot find image #{@execution_environment.docker_image}!") unless @image
  end

  def self.initialize_environment
    unless config[:connection_timeout] && config[:workspace_root]
      fail(Error, 'Docker configuration missing!')
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
    Pathname.new(container.binds.first.split(':').first.sub(config[:workspace_root], LOCAL_WORKSPACE_ROOT.to_s)) if container.binds.present?
  end

  def self.mapped_directories(local_workspace_path)
    remote_workspace_path = local_workspace_path.sub(LOCAL_WORKSPACE_ROOT.to_s, config[:workspace_root])
    # create the string to be returned
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

  def self.return_container(container, execution_environment)
    Rails.logger.debug('returning container ' + container.to_s)
    clean_container_workspace(container)
    DockerContainerPool.return_container(container, execution_environment)
    container.status = :returned
  end
  #private :return_container

  def send_command(command, container, &block)
    result = {status: :failed, stdout: '', stderr: ''}
    Timeout.timeout(@execution_environment.permitted_execution_time.to_i) do
      output = container.exec(['bash', '-c', command])
      Rails.logger.info "output from container.exec"
      Rails.logger.info output
      result = {status: output[2] == 0 ? :ok : :failed, stdout: output[0].join, stderr: output[1].join}
    end
    # if we use pooling and recylce the containers, put it back. otherwise, destroy it.
    (DockerContainerPool.config[:active] && RECYCLE_CONTAINERS) ? self.class.return_container(container, @execution_environment) : self.class.destroy_container(container)
    result
  rescue Timeout::Error
    Rails.logger.info('got timeout error for container ' + container.to_s)

    # remove container from pool, then destroy it
    if (DockerContainerPool.config[:active])
      DockerContainerPool.remove_from_all_containers(container, @execution_environment)
    end

    # destroy container
    self.class.destroy_container(container)

    # if we recylce containers, we start a fresh one
    if(DockerContainerPool.config[:active] && RECYCLE_CONTAINERS)
      # create new container and add it to @all_containers and @containers.
      container = self.class.create_container(@execution_environment)
      DockerContainerPool.add_to_all_containers(container, @execution_environment)
    end
    {status: :timeout}
  end
  private :send_command

  class Error < RuntimeError; end
end
