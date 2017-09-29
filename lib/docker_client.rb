require 'concurrent'
require 'pathname'

class DockerClient
  CONTAINER_WORKSPACE_PATH = '/workspace' #'/home/python/workspace' #'/tmp/workspace'
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
    # remove files when using transferral via Docker API archive_in (transmit)
    #container.exec(['bash', '-c', 'rm -rf ' + CONTAINER_WORKSPACE_PATH + '/*'])

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
      #'HostConfig' => { 'CpusetCpus' => '0', 'CpuQuota' => 10000 },
      #DockerClient.config['allowed_cpus']
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

    socket_url = DockerClient.config['ws_host'] + '/v1.27/containers/' + @container.id + '/attach/ws?' + query_params
    socket = Faye::WebSocket::Client.new(socket_url, [], :headers => headers)

    Rails.logger.debug "Opening Websocket on URL " + socket_url

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
    #Rails.logger.info "docker_client: self.create_container with creation options:"
    #Rails.logger.info(container_creation_options(execution_environment))
    container = Docker::Container.create(container_creation_options(execution_environment))
    # container.start sometimes creates the passed local_workspace_path on disk (depending on the setup).
    # this is however not guaranteed and caused issues on the server already. Therefore create the necessary folders manually!
    local_workspace_path = generate_local_workspace_path
    FileUtils.mkdir(local_workspace_path)
    container.start(container_start_options(execution_environment, local_workspace_path))
    container.start_time = Time.now
    container.status = :created
    container
  rescue Docker::Error::NotFoundError => error
    Rails.logger.error('create_container: Got Docker::Error::NotFoundError: ' + error.to_s)
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
  rescue Docker::Error::NotFoundError => error
    Rails.logger.info('create_workspace_files: Rescued from Docker::Error::NotFoundError: ' + error.to_s)
  end
  private :create_workspace_files

  def create_workspace_file(options = {})
    #TODO: try catch i/o exception and log failed attempts
    file = File.new(local_file_path(options), 'w')
    file.write(options[:file].content)
    file.close
  end
  private :create_workspace_file

  def create_workspace_files_transmit(container, submission)
    begin
    # create a temporary dir, put all files in it, and put it into the container. the dir is automatically removed when leaving the block.
    Dir.mktmpdir {|dir|
      submission.collect_files.each do |file|
        disk_file = File.new(dir + '/' + (file.path || '') + file.name_with_extension, 'w')
        disk_file.write(file.content)
        disk_file.close
      end


      begin
        # create target folder, TODO re-active this when we remove shared folder bindings
        #container.exec(['bash', '-c', 'mkdir ' + CONTAINER_WORKSPACE_PATH])
        #container.exec(['bash', '-c', 'chown -R python ' + CONTAINER_WORKSPACE_PATH])
        #container.exec(['bash', '-c', 'chgrp -G python ' + CONTAINER_WORKSPACE_PATH])
      rescue StandardError => error
        Rails.logger.error('create workspace folder: Rescued from StandardError: ' + error.to_s)
      end

      #sleep 1000

      begin
        # tar the files in dir and put the tar to CONTAINER_WORKSPACE_PATH in the container
        container.archive_in(dir, CONTAINER_WORKSPACE_PATH, overwrite: false)

      rescue StandardError => error
        Rails.logger.error('insert tar: Rescued from StandardError: ' + error.to_s)
      end

      #Rails.logger.info('command: tar -xf ' + CONTAINER_WORKSPACE_PATH  + '/' + dir.split('/tmp/')[1] + ' -C ' + CONTAINER_WORKSPACE_PATH)

      begin
        # untar the tar file placed in the CONTAINER_WORKSPACE_PATH
        container.exec(['bash', '-c', 'tar -xf ' + CONTAINER_WORKSPACE_PATH  + '/' + dir.split('/tmp/')[1] + ' -C ' + CONTAINER_WORKSPACE_PATH])
      rescue StandardError => error
        Rails.logger.error('untar: Rescued from StandardError: ' + error.to_s)
      end


      #sleep 1000

    }
    rescue StandardError => error
      Rails.logger.error('create_workspace_files_transmit: Rescued from StandardError: ' + error.to_s)
    end
  end

  def self.destroy_container(container)
    Rails.logger.info('destroying container ' + container.to_s)
    container.stop.kill
    container.port_bindings.values.each { |port| PortPool.release(port) }
    clean_container_workspace(container)
    if(container)
      container.delete(force: true, v: true)
    end
  rescue Docker::Error::NotFoundError => error
    Rails.logger.error('destroy_container: Rescued from Docker::Error::NotFoundError: ' + error.to_s)
    Rails.logger.error('No further actions are done concerning that.')
  end

  #currently only used to check if containers have been started correctly, or other internal checks
  def execute_arbitrary_command(command, &block)
    execute_command(command, nil, block)
  end

  #only used by score
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

  #called when the user clicks the "Run" button
  def open_websocket_connection(command, before_execution_block, output_consuming_block)
    @container = DockerContainerPool.get_container(@execution_environment)
    if @container
      @container.status = :executing
      # do not use try here, directly call the passed proc and rescue from the error in order to log the problem.
      #before_execution_block.try(:call)
      begin
        before_execution_block.call
      rescue StandardError => error
        Rails.logger.error('execute_websocket_command: Rescued from StandardError caused by before_execution_block.call: ' + error.to_s)
      end
      # TODO: catch exception if socket could not be created
      @socket ||= create_socket(@container)
      {status: :container_running, socket: @socket, container: @container, command: command}
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
        #begin
          timeout = @execution_environment.permitted_execution_time.to_i # seconds
          sleep(timeout)
          if container.status != :returned
            Rails.logger.info('Killing container after timeout of ' + timeout.to_s + ' seconds.')
            # send timeout to the tubesock socket
            if(@tubesock)
              @tubesock.send_data JSON.dump({'cmd' => 'timeout'})
            end
            if(@socket)
              @socket.send('#timeout')
              #sleep one more second to ensure that the message reaches the submissions_controller.
              sleep(1)
              @socket.close
            end
            kill_container(container)
          end
        #ensure
        # guarantee that the thread is releasing the DB connection after it is done
        # ActiveRecord::Base.connectionpool.releaseconnection
        #end
      end
  end

  def exit_thread_if_alive
    if(@thread && @thread.alive?)
      @thread.exit
    end
  end

  def exit_container(container)
    Rails.logger.debug('exiting container ' + container.to_s)
    # exit the timeout thread if it is still alive
    exit_thread_if_alive
    @socket.close
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
    exit_thread_if_alive
  end

  def execute_run_command(submission, filename, &block)
    """
    Run commands by attaching a websocket to Docker.
    """
    command = submission.execution_environment.run_command % command_substitutions(filename)
    create_workspace_files = proc { create_workspace_files(container, submission) }
    open_websocket_connection(command, create_workspace_files, block)
    # actual run command is run in the submissions controller, after all listeners are attached.
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
    # todo: cache this.
    Docker::Image.all.detect { |image| image.info['RepoTags'].flatten.include?(tag) }
  end

  def self.generate_local_workspace_path
    File.join(LOCAL_WORKSPACE_ROOT, SecureRandom.uuid)
  end

  def self.image_tags
    Docker::Image.all.map { |image| image.info['RepoTags'] }.flatten.reject { |tag| tag.nil? || tag.include?('<none>') }
  end

  def initialize(options = {})
    @execution_environment = options[:execution_environment]
    # todo: eventually re-enable this if it is cached. But in the end, we do not need this.
    # docker daemon got much too much load. all not 100% necessary calls to the daemon were removed.
    #@image = self.class.find_image_by_tag(@execution_environment.docker_image)
    #fail(Error, "Cannot find image #{@execution_environment.docker_image}!") unless @image
  end

  def self.initialize_environment
    unless config[:connection_timeout] && config[:workspace_root]
      fail(Error, 'Docker configuration missing!')
    end
    Docker.url = config[:host] if config[:host]
    # todo: availability check disabled for performance reasons. Reconsider if this is necessary.
    # docker daemon got much too much load. all not 100% necessary calls to the daemon were removed.
    # check_availability!
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
    begin
      clean_container_workspace(container)
    rescue Docker::Error::NotFoundError => error
      Rails.logger.info('return_container: Rescued from Docker::Error::NotFoundError: ' + error.to_s)
      Rails.logger.info('Nothing is done here additionally. The container will be exchanged upon its next retrieval.')
    end
    DockerContainerPool.return_container(container, execution_environment)
    container.status = :returned
  end
  #private :return_container

  def send_command(command, container, &block)
    result = {status: :failed, stdout: '', stderr: ''}
    Timeout.timeout(@execution_environment.permitted_execution_time.to_i) do
      #TODO: check phusion doku again if we need -i -t options here
      output = container.exec(['bash', '-c', command])
      Rails.logger.debug "output from container.exec"
      Rails.logger.debug output
      if(output == nil)
        kill_container(container)
      end
      result = {status: output[2] == 0 ? :ok : :failed, stdout: output[0].join.force_encoding('utf-8'), stderr: output[1].join.force_encoding('utf-8')}
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
