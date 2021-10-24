# frozen_string_literal: true

class Runner::Strategy::DockerContainerPool < Runner::Strategy
  attr_reader :container_id, :command

  def self.config
    # Since the docker configuration file contains code that must be executed, we use ERB templating.
    @config ||= CodeOcean::Config.new(:docker).read(erb: true)
  end

  def self.initialize_environment
    DockerClient.initialize_environment unless Rails.env.test? && `which docker`.blank?
  end

  def self.available_images
    DockerClient.check_availability!
    DockerClient.image_tags
  rescue DockerClient::Error => e
    raise Runner::Error::InternalServerError.new(e.message)
  end

  def self.sync_environment(_environment)
    # There is no dedicated sync mechanism yet
    true
  end

  def self.request_from_management(environment)
    url = "#{config[:pool][:location]}/docker_container_pool/get_container/#{environment.id}"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Requesting new runner at #{url}" }
    response = Faraday.get url
    container_id = JSON.parse(response.body)['id']
    container_id.presence || raise(Runner::Error::NotAvailable.new("DockerContainerPool didn't return a container id"))
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  rescue JSON::ParserError => e
    raise Runner::Error::UnexpectedResponse.new("DockerContainerPool returned invalid JSON: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished new runner request" }
  end

  def initialize(runner_id, _environment)
    super
    @container_id = runner_id
  end

  def copy_files(files)
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Sending files to #{local_workspace_path}" }
    FileUtils.mkdir_p(local_workspace_path)
    clean_workspace
    files.each do |file|
      if file.path.present?
        local_directory_path = local_path(file.path)
        FileUtils.mkdir_p(local_directory_path)
      end

      local_file_path = local_path(file.filepath)
      if file.file_type.binary?
        FileUtils.cp(file.native_file.path, local_file_path)
      else
        begin
          File.open(local_file_path, 'w') {|f| f.write(file.content) }
        rescue IOError => e
          raise Runner::Error::WorkspaceError.new("Could not create file #{file.filepath}: #{e.inspect}")
        end
      end
    end
    FileUtils.chmod_R('+rwtX', local_workspace_path)
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished copying files" }
  end

  def destroy_at_management
    url = "#{self.class.config[:pool][:location]}/docker_container_pool/destroy_container/#{container.id}"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Destroying runner at #{url}" }
    Faraday.get(url)
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished destroying runner" }
  end

  def attach_to_execution(command, event_loop)
    @command = command
    query_params = 'logs=0&stream=1&stderr=1&stdout=1&stdin=1'
    websocket_url = "#{self.class.config[:ws_host]}/v1.27/containers/#{@container_id}/attach/ws?#{query_params}"

    socket = Connection.new(websocket_url, self, event_loop)
    begin
      Timeout.timeout(@execution_environment.permitted_execution_time) do
        socket.send_data(command)
        yield(socket)
        event_loop.wait
        event_loop.stop
      end
    rescue Timeout::Error
      socket.close(:timeout)
      destroy_at_management
    end
    socket
  end

  def websocket_header
    {}
  end

  private

  def container
    return @container if @container.present?

    @container = Docker::Container.get(@container_id)
    raise Runner::Error::RunnerNotFound unless @container.info['State']['Running']

    @container
  rescue Docker::Error::NotFoundError
    raise Runner::Error::RunnerNotFound
  end

  def local_path(path)
    unclean_path = local_workspace_path.join(path)
    clean_path = File.expand_path(unclean_path)
    unless clean_path.to_s.start_with? local_workspace_path.to_s
      raise Runner::Error::WorkspaceError.new("Local filepath #{clean_path.inspect} not allowed")
    end

    Pathname.new(clean_path)
  end

  def clean_workspace
    FileUtils.rm_r(local_workspace_path.children, secure: true)
  rescue Errno::ENOENT => e
    raise Runner::Error::WorkspaceError.new("The workspace directory does not exist and cannot be deleted: #{e.inspect}")
  rescue Errno::EACCES => e
    raise Runner::Error::WorkspaceError.new("Not allowed to clean workspace #{local_workspace_path}: #{e.inspect}")
  end

  def local_workspace_path
    @local_workspace_path ||= Pathname.new(container.binds.first.split(':').first)
  end

  class Connection < Runner::Connection
    def initialize(*args)
      @stream = 'stdout'
      super
    end

    def encode(data)
      "#{data}\n"
    end

    def decode(event_data)
      case event_data
        when /(@#{@strategy.container_id[0..11]}|#exit|{"cmd": "exit"})/
          # TODO: The whole message line is kept back. If this contains the remaining buffer, this buffer is also lost.
          # Example: A Java program prints `{` and then exists (with `#exit`). The `event_data` processed here is `{#exit`

          # Assume correct termination for now and return exit code 0
          # TODO: Can we use the actual exit code here?
          @exit_code = 0
          close(:terminated_by_codeocean)
        when /python3.*-m\s*unittest/
          # TODO: Super dirty hack to redirect test output to stderr
          # This is only required for Python and the unittest module but must not be used with PyLint
          @stream = 'stderr'
        when /\*\*\*\*\*\*\*\*\*\*\*\*\* Module/
          # Identification of PyLint output, change stream back to stdout and return event
          @stream = 'stdout'
          {'type' => @stream, 'data' => event_data}
        when /#{Regexp.quote(@strategy.command)}/
        when /bash: cmd:canvasevent: command not found/
        else
          {'type' => @stream, 'data' => event_data}
      end
    end
  end
end
