# frozen_string_literal: true

class Runner::Strategy::Poseidon < Runner::Strategy
  ERRORS = %w[NOMAD_UNREACHABLE NOMAD_OVERLOAD NOMAD_INTERNAL_SERVER_ERROR UNKNOWN].freeze

  ERRORS.each do |error|
    define_singleton_method :"error_#{error.downcase}" do
      error
    end
  end

  def initialize(runner_id, _environment)
    super
    @allocation_id = runner_id
  end

  def self.initialize_environment
    # There is no additional initialization required for Poseidon
    nil
  end

  def self.environments
    url = "#{config[:url]}/execution-environments"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Getting list of execution environments at #{url}" }
    response = http_connection.get url

    case response.status
      when 200
        response_body = parse response
        execution_environments = response_body[:executionEnvironments]

        if execution_environments.nil?
          raise(Runner::Error::UnexpectedResponse.new("Could not get the list of execution environments in Poseidon, got response: #{response.as_json}"))
        else
          execution_environments
        end
      when 404
        raise Runner::Error::EnvironmentNotFound.new
      else
        handle_error response
    end
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Could not get the list of execution environments because of Faraday error: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished getting the list of execution environments" }
  end

  def self.sync_environment(environment)
    url = "#{config[:url]}/execution-environments/#{environment.id}"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Synchronizing execution environment at #{url}" }
    response = http_connection.put url, environment.to_json
    return true if [201, 204].include? response.status

    raise Runner::Error::UnexpectedResponse.new("Could not synchronize execution environment in Poseidon, got response: #{response.as_json}")
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Could not synchronize execution environment because of Faraday error: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished synchronizing execution environment" }
  end

  def self.remove_environment(environment)
    url = "#{config[:url]}/execution-environments/#{environment.id}"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Deleting execution environment at #{url}" }
    response = http_connection.delete url
    return true if response.status == 204

    raise Runner::Error::UnexpectedResponse.new("Could not delete execution environment in Poseidon, got response: #{response.as_json}")
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Could not delete execution environment because of Faraday error: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished deleting execution environment" }
  end

  def self.request_from_management(environment)
    url = "#{config[:url]}/runners"
    inactivity_timeout = [config[:unused_runner_expiration_time], environment.permitted_execution_time].max
    body = {
      executionEnvironmentId: environment.id,
      inactivityTimeout: inactivity_timeout.to_i.seconds,
    }
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Requesting new runner at #{url}" }
    response = http_connection.post url, body.to_json

    case response.status
      when 200
        response_body = parse response
        runner_id = response_body[:runnerId]
        runner_id.presence || raise(Runner::Error::UnexpectedResponse.new('Poseidon did not send a runner id'))
      when 404
        raise Runner::Error::EnvironmentNotFound.new
      else
        handle_error response
    end
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished new runner request" }
  end

  def destroy_at_management
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Destroying runner at #{runner_url}" }
    response = self.class.http_connection.delete runner_url
    self.class.handle_error response unless response.status == 204
  rescue Runner::Error::RunnerNotFound
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Runner not found, nothing to destroy" }
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished destroying runner" }
  end

  def copy_files(files)
    url = "#{runner_url}/files"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Sending files to #{url}" }

    copy = files.map do |file|
      {
        path: file.filepath,
        content: Base64.strict_encode64(file.read || ''),
      }
    end

    # First, clean the workspace and second, copy all files to their location.
    # This ensures that no artifacts from a previous submission remain in the workspace.
    body = {copy: copy, delete: ['./*']}
    response = self.class.http_connection.patch url, body.to_json
    return if response.status == 204

    Runner.destroy(@allocation_id) if response.status == 400
    self.class.handle_error response
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished copying files" }
  end

  def attach_to_execution(command, event_loop, starting_time)
    websocket_url = execute_command(command)
    socket = Connection.new(websocket_url, self, event_loop)
    yield(socket, starting_time)
    socket
  end

  def self.available_images
    # Images are pulled when needed for a new execution environment
    # and cleaned up automatically if no longer in use.
    # Hence, there is no additional image that we need to return
    []
  end

  def self.config
    @config ||= CodeOcean::Config.new(:code_ocean).read[:runner_management] || {}
  end

  def self.release
    url = "#{config[:url]}/version"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Getting release from #{url}" }
    response = http_connection.get url
    case response.status
      when 200
        JSON.parse(response.body)
      when 404
        'N/A'
      else
        handle_error response
    end
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  rescue JSON::ParserError => e
    # Poseidon should not send invalid json
    raise Runner::Error::UnexpectedResponse.new("Error parsing response from Poseidon: #{e.message}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished getting release information" }
  end

  def self.pool_size
    url = "#{config[:url]}/statistics/execution-environments"
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Getting statistics from #{url}" }
    response = http_connection.get url
    case response.status
      when 200
        response_body = parse response
        response_body
      else
        handle_error response
    end
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  rescue JSON::ParserError => e
    # Poseidon should not send invalid json
    raise Runner::Error::UnexpectedResponse.new("Error parsing response from Poseidon: #{e.message}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished getting statistics" }
  end

  def self.websocket_header
    # The `tls` option is used to customize the validation of TLS connections.
    # The `headers` option is used to pass the `Poseidon-Token` as part of the initial connection request.
    {
      tls: {root_cert_file: config[:ca_file]},
      headers: {'Poseidon-Token' => config[:token]},
    }
  end

  def self.handle_error(response)
    case response.status
      when 400
        response_body = parse response
        raise Runner::Error::BadRequest.new(response_body[:message])
      when 401
        raise Runner::Error::Unauthorized.new('Authentication with Poseidon failed')
      when 404
        raise Runner::Error::RunnerNotFound.new
      when 500
        response_body = parse response
        error_code = response_body[:errorCode]
        if error_code == error_nomad_overload
          raise Runner::Error::NotAvailable.new("Poseidon has no runner available (#{error_code}): #{response_body[:message]}")
        else
          raise Runner::Error::InternalServerError.new("Poseidon sent #{response_body[:errorCode]}: #{response_body[:message]}")
        end
      else
        raise Runner::Error::UnexpectedResponse.new("Poseidon sent unexpected response status code #{response.status}")
    end
  end

  def self.headers
    @headers ||= {'Content-Type' => 'application/json', 'Poseidon-Token' => config[:token]}
  end

  def self.http_connection
    @http_connection ||= Faraday.new(ssl: {ca_file: config[:ca_file]}, headers: headers) do |faraday|
      faraday.adapter :net_http_persistent
    end
  end

  def self.parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  rescue JSON::ParserError => e
    # Poseidon should not send invalid json
    raise Runner::Error::UnexpectedResponse.new("Error parsing response from Poseidon: #{e.message}")
  end

  private

  def execute_command(command)
    url = "#{runner_url}/execute"
    body = {
      command: command,
      timeLimit: @execution_environment.permitted_execution_time,
      privilegedExecution: @execution_environment.privileged_execution,
    }
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Preparing command execution at #{url}: #{command}" }
    response = self.class.http_connection.post url, body.to_json

    case response.status
      when 200
        response_body = self.class.parse response
        websocket_url = response_body[:websocketUrl]
        websocket_url.presence || raise(Runner::Error::UnexpectedResponse.new('Poseidon did not send a WebSocket URL'))
      when 400
        Runner.destroy(@allocation_id)
        self.class.handle_error response
      else
        self.class.handle_error response
    end
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  ensure
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Finished command execution preparation" }
  end

  def runner_url
    "#{self.class.config[:url]}/runners/#{@allocation_id}"
  end

  class Connection < Runner::Connection
    def decode(event_data)
      JSON.parse(event_data)
    rescue JSON::ParserError => e
      @error = Runner::Error::UnexpectedResponse.new("The WebSocket message from Poseidon could not be decoded to JSON: #{e.inspect}")
      close(:error)
    end

    def encode(data)
      "#{data}\n"
    end
  end
end
