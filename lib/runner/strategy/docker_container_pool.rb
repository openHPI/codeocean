# frozen_string_literal: true

class Runner::Strategy::DockerContainerPool < Runner::Strategy
  attr_reader :container_id, :command

  def initialize(runner_id, _environment)
    super
    @container_id = runner_id
  end

  def self.initialize_environment
    raise Error.new('Docker configuration missing!') unless config[:host] && config[:workspace_root]

    FileUtils.mkdir_p(File.expand_path(config[:workspace_root]))
  end

  def self.sync_environment(_environment)
    # There is no dedicated sync mechanism yet
    true
  end

  def self.request_from_management(environment)
    url = "#{config[:url]}/docker_container_pool/get_container/#{environment.id}"
    body = {
      inactivity_timeout: config[:unused_runner_expiration_time].seconds,
    }
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Requesting new runner at #{url}" }
    response = Faraday.post url, body

    container_id = JSON.parse(response.body)['id']
    container_id.presence || raise(Runner::Error::NotAvailable.new("DockerContainerPool didn't return a container id"))
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  rescue JSON::ParserError => e
    raise Runner::Error::UnexpectedResponse.new("DockerContainerPool returned invalid JSON: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished new runner request" }
  end

  def destroy_at_management
    url = "#{self.class.config[:url]}/docker_container_pool/destroy_container/#{container.id}"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Destroying runner at #{url}" }
    Faraday.delete(url)
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished destroying runner" }
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

  def attach_to_execution(command, event_loop)
    reset_inactivity_timer

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

  def self.available_images
    url = "#{config[:url]}/docker_container_pool/available_images"
    response = Faraday.get(url)
    json = JSON.parse(response.body)
    return json if response.success?

    raise Runner::Error::InternalServerError.new("DockerContainerPool returned: #{json['error']}")
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  rescue JSON::ParserError => e
    raise Runner::Error::UnexpectedResponse.new("DockerContainerPool returned invalid JSON: #{e.inspect}")
  end

  def self.config
    @config ||= begin
      # Since the docker configuration file contains code that must be executed, we use ERB templating.
      docker_config = CodeOcean::Config.new(:docker).read(erb: true)
      codeocean_config = CodeOcean::Config.new(:code_ocean).read[:runner_management] || {}
      # All keys in `docker_config` take precedence over those in `codeocean_config`
      docker_config.merge codeocean_config
    end
  end

  def self.release
    url = "#{config[:url]}/docker_container_pool/dump_info"
    response = Faraday.get(url)
    JSON.parse(response.body)['release']
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  rescue JSON::ParserError => e
    raise Runner::Error::UnexpectedResponse.new("DockerContainerPool returned invalid JSON: #{e.inspect}")
  end

  def self.pool_size
    url = "#{config[:url]}/docker_container_pool/quantities"
    response = Faraday.get(url)
    pool_size = JSON.parse(response.body)
    pool_size.transform_keys(&:to_i)
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  rescue JSON::ParserError => e
    raise Runner::Error::UnexpectedResponse.new("DockerContainerPool returned invalid JSON: #{e.inspect}")
  end

  def self.websocket_header
    # The `ping` value is measured in seconds and specifies how often a Ping frame should be sent.
    # Internally, Faye::WebSocket uses EventMachine and the `ping` value is used to wake the EventMachine thread
    {
      ping: 0.1,
    }
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

  def reset_inactivity_timer
    url = "#{self.class.config[:url]}/docker_container_pool/reuse_container/#{container.id}"
    body = {
      inactivity_timeout: self.class.config[:unused_runner_expiration_time].seconds,
    }
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Resetting inactivity timer at #{url}" }
    Faraday.post url, body
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to DockerContainerPool failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished resetting inactivity timer" }
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
        when /(?<previous_data>.*)((root|python|user)@#{@strategy.container_id[0..11]}|#exit|{"cmd": "exit"})/m
          # The RegEx above is used to determine unwanted output which also indicates a program termination.
          # If the RegEx matches, at least two capture groups will be created.
          # The first (called `previous_data`) contains any data before the match (including multiple lines)
          # while the second contains the unwanted output data.

          # Assume correct termination for now and return exit code 0
          # TODO: Can we use the actual exit code here?
          @exit_code = 0
          close(:terminated_by_codeocean)

          # The first capture group is forwarded
          {'type' => @stream, 'data' => Regexp.last_match(:previous_data)}
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
