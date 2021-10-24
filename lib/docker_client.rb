# frozen_string_literal: true

require 'pathname'

class DockerClient
  def self.config
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)
  end

  CONTAINER_WORKSPACE_PATH = '/workspace' # '/home/python/workspace' #'/tmp/workspace'
  # Ralf: I suggest to replace this with the environment variable. Ask Hauke why this is not the case!
  LOCAL_WORKSPACE_ROOT = File.expand_path(config[:workspace_root])
  RECYCLE_CONTAINERS = false
  RETRY_COUNT = 2
  MINIMUM_CONTAINER_LIFETIME = 10.minutes
  MAXIMUM_CONTAINER_LIFETIME = 20.minutes
  SELF_DESTROY_GRACE_PERIOD = 2.minutes

  attr_reader :container, :socket
  attr_accessor :tubesock

  def self.check_availability!
    Timeout.timeout(config[:connection_timeout]) { Docker.version }
  rescue Excon::Errors::SocketError, Timeout::Error
    raise Error.new("The Docker host at #{Docker.url} is not reachable!")
  end

  def self.clean_container_workspace(container)
    # remove files when using transferral via Docker API archive_in (transmit)
    # container.exec(['bash', '-c', 'rm -rf ' + CONTAINER_WORKSPACE_PATH + '/*'])

    local_workspace_path = local_workspace_path(container)
    if local_workspace_path && Pathname.new(local_workspace_path).exist?
      Pathname.new(local_workspace_path).children.each do |p|
        p.rmtree
      rescue Errno::ENOENT, Errno::EACCES => e
        Sentry.capture_exception(e)
        Rails.logger.error("clean_container_workspace: Got #{e.class}: #{e}")
      end
      # FileUtils.rmdir(Pathname.new(local_workspace_path))
    end
  end

  def command_substitutions(filename)
    {
      class_name: File.basename(filename, File.extname(filename)).upcase_first,
      filename: filename,
      module_name: File.basename(filename, File.extname(filename)).underscore,
    }
  end

  private :command_substitutions

  def self.container_creation_options(execution_environment, local_workspace_path)
    {
      'Image' => find_image_by_tag(execution_environment.docker_image).info['RepoTags'].first,
      'NetworkDisabled' => !execution_environment.network_enabled?,
      # DockerClient.config['allowed_cpus']
      'OpenStdin' => true,
      'StdinOnce' => true,
      # required to expose standard streams over websocket
      'AttachStdout' => true,
      'AttachStdin' => true,
      'AttachStderr' => true,
      'Tty' => true,
      'Binds' => mapped_directories(local_workspace_path),
      'PortBindings' => mapped_ports(execution_environment),
      # Resource limitations.
      'NanoCPUs' => 4 * 1_000_000_000, # CPU quota in units of 10^-9 CPUs.
      'PidsLimit' => 100,
      'KernelMemory' => execution_environment.memory_limit.megabytes, # if below Memory, the Docker host (!) might experience an OOM
      'Memory' => execution_environment.memory_limit.megabytes,
      'MemorySwap' => execution_environment.memory_limit.megabytes, # same value as Memory to disable Swap
      'OomScoreAdj' => 500,
    }
  end

  def create_socket(container, stderr: false)
    # TODO: factor out query params
    # todo separate stderr
    query_params = "logs=0&stream=1&#{stderr ? 'stderr=1' : 'stdout=1&stdin=1'}"

    # Headers are required by Docker
    headers = {'Origin' => 'http://localhost'}

    socket_url = "#{DockerClient.config['ws_host']}/v1.27/containers/#{@container.id}/attach/ws?#{query_params}"
    # The ping value is measured in seconds and specifies how often a Ping frame should be sent.
    # Internally, Faye::WebSocket uses EventMachine and the ping value is used to wake the EventMachine thread
    socket = Faye::WebSocket::Client.new(socket_url, [], headers: headers, ping: 0.1)

    Rails.logger.debug { "Opening Websocket on URL #{socket_url}" }

    socket.on :error do |event|
      Rails.logger.info "Websocket error: #{event.message}"
    end
    socket.on :close do |_event|
      Rails.logger.info 'Websocket closed.'
    end
    socket.on :open do |_event|
      Rails.logger.info 'Websocket created.'
      kill_after_timeout(container)
    end
    socket
  end

  def copy_file_to_workspace(options = {})
    FileUtils.cp(options[:file].native_file.path, local_file_path(options))
  end

  def self.create_container(execution_environment)
    # tries ||= 0
    # container.start sometimes creates the passed local_workspace_path on disk (depending on the setup).
    # this is however not guaranteed and caused issues on the server already. Therefore create the necessary folders manually!
    local_workspace_path = generate_local_workspace_path
    FileUtils.mkdir(local_workspace_path)
    FileUtils.chmod_R(0o777, local_workspace_path)
    container = Docker::Container.create(container_creation_options(execution_environment, local_workspace_path))
    container.start
    container.start_time = Time.zone.now
    container.status = :created
    container.execution_environment = execution_environment
    container.re_use = true
    container.docker_client = new(execution_environment: execution_environment)

    Thread.new do
      timeout = Random.rand(MINIMUM_CONTAINER_LIFETIME..MAXIMUM_CONTAINER_LIFETIME) # seconds
      sleep(timeout)
      container.re_use = false
      if container.status == :executing
        Thread.new do
          timeout = SELF_DESTROY_GRACE_PERIOD.to_i
          sleep(timeout)
          container.docker_client.kill_container(container)
          Rails.logger.info("Force killing container in status #{container.status} after #{Time.zone.now - container.start_time} seconds.")
        ensure
          # guarantee that the thread is releasing the DB connection after it is done
          ActiveRecord::Base.connection_pool.release_connection
        end
      else
        container.docker_client.kill_container(container)
        Rails.logger.info("Killing container in status #{container.status} after #{Time.zone.now - container.start_time} seconds.")
      end
    ensure
      # guarantee that the thread is releasing the DB connection after it is done
      ActiveRecord::Base.connection_pool.release_connection
    end

    container
  rescue Docker::Error::NotFoundError => e
    Rails.logger.error("create_container: Got Docker::Error::NotFoundError: #{e}")
    destroy_container(container)
    # (tries += 1) <= RETRY_COUNT ? retry : raise(error)
  end

  def create_workspace_files(container, submission)
    # clear directory (it should be empty anyhow)
    # Pathname.new(self.class.local_workspace_path(container)).children.each{ |p| p.rmtree}
    submission.collect_files.each do |file|
      FileUtils.mkdir_p(File.join(self.class.local_workspace_path(container), file.path || ''))
      if file.file_type.binary?
        copy_file_to_workspace(container: container, file: file)
      else
        create_workspace_file(container: container, file: file)
      end
    end
    FileUtils.chmod_R('+rwX', self.class.local_workspace_path(container))
  rescue Docker::Error::NotFoundError => e
    Rails.logger.info("create_workspace_files: Rescued from Docker::Error::NotFoundError: #{e}")
  end

  private :create_workspace_files

  def create_workspace_file(options = {})
    # TODO: try catch i/o exception and log failed attempts
    file = File.new(local_file_path(options), 'w')
    file.write(options[:file].content)
    file.close
  end

  private :create_workspace_file

  def create_workspace_files_transmit(container, submission)
    # create a temporary dir, put all files in it, and put it into the container. the dir is automatically removed when leaving the block.
    Dir.mktmpdir do |dir|
      submission.collect_files.each do |file|
        disk_file = File.new("#{dir}/#{file.path || ''}#{file.name_with_extension}", 'w')
        disk_file.write(file.content)
        disk_file.close
      end

      begin
        # create target folder, TODO re-active this when we remove shared folder bindings
        # container.exec(['bash', '-c', 'mkdir ' + CONTAINER_WORKSPACE_PATH])
        # container.exec(['bash', '-c', 'chown -R python ' + CONTAINER_WORKSPACE_PATH])
        # container.exec(['bash', '-c', 'chgrp -G python ' + CONTAINER_WORKSPACE_PATH])
      rescue StandardError => e
        Rails.logger.error("create workspace folder: Rescued from StandardError: #{e}")
      end

      # sleep 1000

      begin
        # tar the files in dir and put the tar to CONTAINER_WORKSPACE_PATH in the container
        container.archive_in(dir, CONTAINER_WORKSPACE_PATH, overwrite: false)
      rescue StandardError => e
        Rails.logger.error("insert tar: Rescued from StandardError: #{e}")
      end

      # Rails.logger.info('command: tar -xf ' + CONTAINER_WORKSPACE_PATH  + '/' + dir.split('/tmp/')[1] + ' -C ' + CONTAINER_WORKSPACE_PATH)

      begin
        # untar the tar file placed in the CONTAINER_WORKSPACE_PATH
        container.exec(['bash', '-c',
                        "tar -xf #{CONTAINER_WORKSPACE_PATH}/#{dir.split('/tmp/')[1]} -C #{CONTAINER_WORKSPACE_PATH}"])
      rescue StandardError => e
        Rails.logger.error("untar: Rescued from StandardError: #{e}")
      end

      # sleep 1000
    end
  rescue StandardError => e
    Rails.logger.error("create_workspace_files_transmit: Rescued from StandardError: #{e}")
  end

  def self.destroy_container(container)
    @socket&.close
    Rails.logger.info("destroying container #{container}")

    # Checks only if container assignment is not nil and not whether the container itself is still present.
    if container && !DockerContainerPool.active?
      container.kill
      container.port_bindings.each_value {|port| PortPool.release(port) }
      begin
        clean_container_workspace(container)
        FileUtils.rmtree(local_workspace_path(container))
      rescue Errno::ENOENT, Errno::EACCES => e
        Sentry.capture_exception(e)
        Rails.logger.error("clean_container_workspace: Got #{e.class}: #{e}")
      end

      # Checks only if container assignment is not nil and not whether the container itself is still present.
      container&.delete(force: true, v: true)
    elsif container
      DockerContainerPool.destroy_container(container)
    end
  rescue Docker::Error::NotFoundError => e
    Rails.logger.error("destroy_container: Rescued from Docker::Error::NotFoundError: #{e}")
    Rails.logger.error('No further actions are done concerning that.')
  rescue Docker::Error::ConflictError => e
    Rails.logger.error("destroy_container: Rescued from Docker::Error::ConflictError: #{e}")
    Rails.logger.error('No further actions are done concerning that.')
  end

  # currently only used to check if containers have been started correctly, or other internal checks
  # also used for the admin shell to any container
  def execute_arbitrary_command(command, &block)
    execute_command(command, nil, block)
  end

  # only used by score and execute_arbitrary_command
  def execute_command(command, before_execution_block, output_consuming_block)
    # tries ||= 0
    container_request_time = Time.zone.now
    @container = DockerContainerPool.get_container(@execution_environment)
    waiting_for_container_time = Time.zone.now - container_request_time
    if @container
      @container.status = :executing
      before_execution_block.try(:call)
      execution_request_time = Time.zone.now
      command_result = send_command(command, @container, &output_consuming_block)
      container_execution_time = Time.zone.now - execution_request_time

      command_result[:waiting_for_container_time] = waiting_for_container_time
      command_result[:container_execution_time] = container_execution_time
      command_result
    else
      {status: :container_depleted, waiting_for_container_time: waiting_for_container_time,
container_execution_time: nil}
    end
  rescue Excon::Errors::SocketError
    # socket errors seems to be normal when using exec
    # so lets ignore them for now
    # (tries += 1) <= RETRY_COUNT ? retry : raise(error)
  end

  # called when the user clicks the "Run" button
  def open_websocket_connection(command, before_execution_block, _output_consuming_block)
    @container = DockerContainerPool.get_container(@execution_environment)
    if @container
      @container.status = :executing
      # do not use try here, directly call the passed proc and rescue from the error in order to log the problem.
      # before_execution_block.try(:call)
      begin
        before_execution_block.call
      rescue FilepathError
        # Prevent catching this error here
        raise
      rescue StandardError => e
        Rails.logger.error("execute_websocket_command: Rescued from StandardError caused by before_execution_block.call: #{e}")
      end
      # TODO: catch exception if socket could not be created
      @socket ||= create_socket(@container)
      {status: :container_running, socket: @socket, container: @container, command: command}
    else
      {status: :container_depleted}
    end
  end

  def kill_after_timeout(container)
    # We need to start a second thread to kill the websocket connection,
    # as it is impossible to determine whether further input is requested.
    container.status = :executing
    @thread = Thread.new do
      timeout = @execution_environment.permitted_execution_time.to_i # seconds
      sleep(timeout)
      if container && container.status != :available
        Rails.logger.info("Killing container after timeout of #{timeout} seconds.")
        # send timeout to the tubesock socket
        # FIXME: 2nd thread to notify user.
        @tubesock&.send_data JSON.dump({'cmd' => 'timeout'})
        if @socket
          begin
            @socket.send('#timeout')
            # sleep one more second to ensure that the message reaches the submissions_controller.
            sleep(1)
            @socket.close
          rescue RuntimeError => e
            Rails.logger.error(e)
          end
        end
        Thread.new do
          kill_container(container)
        ensure
          ActiveRecord::Base.connection_pool.release_connection
        end
      else
        Rails.logger.info("Container#{container} already removed.")
      end
    ensure
      # guarantee that the thread is releasing the DB connection after it is done
      ActiveRecord::Base.connection_pool.release_connection
    end
  end

  def exit_thread_if_alive
    @thread.exit if @thread&.alive?
  end

  def exit_container(container)
    Rails.logger.debug { "exiting container #{container}" }
    # exit the timeout thread if it is still alive
    exit_thread_if_alive
    @socket.close
    # if we use pooling and recylce the containers, put it back. otherwise, destroy it.
    if DockerContainerPool.active? && RECYCLE_CONTAINERS
      self.class.return_container(container,
        @execution_environment)
    else
      self.class.destroy_container(container)
    end
  end

  def kill_container(container)
    exit_thread_if_alive
    Rails.logger.info("killing container #{container}")
    self.class.destroy_container(container)
  end

  def execute_run_command(submission, filename, &block)
    # Run commands by attaching a websocket to Docker.
    filepath = submission.collect_files.find {|f| f.name_with_extension == filename }.filepath
    command = submission.execution_environment.run_command % command_substitutions(filepath)
    create_workspace_files = proc { create_workspace_files(container, submission) }
    open_websocket_connection(command, create_workspace_files, block)
    # actual run command is run in the submissions controller, after all listeners are attached.
  end

  def execute_test_command(submission, filename, &block)
    # Stick to existing Docker API with exec command.
    file = submission.collect_files.find {|f| f.name_with_extension == filename }
    filepath = file.filepath
    command = submission.execution_environment.test_command % command_substitutions(filepath)
    create_workspace_files = proc { create_workspace_files(container, submission) }
    test_result = execute_command(command, create_workspace_files, block)
    test_result[:file_role] = file.role
    test_result
  end

  def self.find_image_by_tag(tag)
    # TODO: cache this.
    Docker::Image.all.detect do |image|
      image.info['RepoTags'].flatten.include?(tag)
    rescue StandardError
      # Skip image if it is not tagged
      next
    end
  end

  def self.generate_local_workspace_path
    File.join(LOCAL_WORKSPACE_ROOT, SecureRandom.uuid)
  end

  def self.image_tags
    Docker::Image.all.map {|image| image.info['RepoTags'] }.flatten.reject {|tag| tag.nil? || tag.include?('<none>') }
  end

  def initialize(options = {})
    @execution_environment = options[:execution_environment]
    # TODO: eventually re-enable this if it is cached. But in the end, we do not need this.
    # docker daemon got much too much load. all not 100% necessary calls to the daemon were removed.
    # @image = self.class.find_image_by_tag(@execution_environment.docker_image)
    # fail(Error, "Cannot find image #{@execution_environment.docker_image}!") unless @image
  end

  def self.initialize_environment
    # TODO: Move to DockerContainerPool
    raise Error.new('Docker configuration missing!') unless config[:connection_timeout] && config[:workspace_root]

    Docker.url = config[:host] if config[:host]
    # TODO: availability check disabled for performance reasons. Reconsider if this is necessary.
    # docker daemon got much too much load. all not 100% necessary calls to the daemon were removed.
    # check_availability!
    FileUtils.mkdir_p(LOCAL_WORKSPACE_ROOT)
  end

  def local_file_path(options = {})
    resulting_file_path = File.join(self.class.local_workspace_path(options[:container]), options[:file].path || '',
      options[:file].name_with_extension)
    absolute_path = File.expand_path(resulting_file_path)
    unless absolute_path.start_with? self.class.local_workspace_path(options[:container]).to_s
      raise FilepathError.new('Filepath not allowed')
    end

    absolute_path
  end

  private :local_file_path

  def self.local_workspace_path(container)
    Pathname.new(container.binds.first.split(':').first) if container.binds.present?
  end

  def self.mapped_directories(local_workspace_path)
    # create the string to be returned
    ["#{local_workspace_path}:#{CONTAINER_WORKSPACE_PATH}"]
  end

  def self.mapped_ports(execution_environment)
    execution_environment.exposed_ports.map do |port|
      ["#{port}/tcp", [{'HostPort' => PortPool.available_port.to_s}]]
    end.to_h
  end

  def self.pull(docker_image)
    `docker pull #{docker_image}` if docker_image
  end

  def self.return_container(container, execution_environment)
    Rails.logger.debug { "returning container #{container}" }
    begin
      clean_container_workspace(container)
    rescue Docker::Error::NotFoundError => e
      # FIXME: Create new container?
      Rails.logger.info("return_container: Rescued from Docker::Error::NotFoundError: #{e}")
      Rails.logger.info('Nothing is done here additionally. The container will be exchanged upon its next retrieval.')
    end
    DockerContainerPool.return_container(container, execution_environment)
    container.status = :available
  end

  # private :return_container

  def send_command(command, container)
    result = {status: :failed, stdout: '', stderr: ''}
    output = nil
    Timeout.timeout(@execution_environment.permitted_execution_time.to_i) do
      # TODO: check phusion doku again if we need -i -t options here
      # https://stackoverflow.com/questions/363223/how-do-i-get-both-stdout-and-stderr-to-go-to-the-terminal-and-a-log-file
      output = container.exec(
        ['bash', '-c',
         "#{command} 1> >(tee -a /tmp/stdout.log) 2> >(tee -a /tmp/stderr.log >&2); rm -f /tmp/std*.log"], tty: false
      )
    end
    Rails.logger.debug 'output from container.exec'
    Rails.logger.debug output
    if output.nil?
      kill_container(container)
    else
      result = {status: (output[2])&.zero? ? :ok : :failed, stdout: output[0].join.force_encoding('utf-8'), stderr: output[1].join.force_encoding('utf-8')}
    end

    # if we use pooling and recylce the containers, put it back. otherwise, destroy it.
    if DockerContainerPool.active? && RECYCLE_CONTAINERS
      self.class.return_container(container, @execution_environment)
    else
      self.class.destroy_container(container)
    end
    result
  rescue Timeout::Error
    Rails.logger.info("got timeout error for container #{container}")
    stdout = container.exec(%w[cat /tmp/stdout.log])[0].join.force_encoding('utf-8')
    stderr = container.exec(%w[cat /tmp/stderr.log])[0].join.force_encoding('utf-8')
    kill_container(container)
    {status: :timeout, stdout: stdout, stderr: stderr}
  end
  private :send_command

  class Error < RuntimeError; end

  class FilepathError < RuntimeError; end
end
