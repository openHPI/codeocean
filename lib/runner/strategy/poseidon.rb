# frozen_string_literal: true

class Runner::Strategy::Poseidon < Runner::Strategy
  ERRORS = %w[NOMAD_UNREACHABLE NOMAD_OVERLOAD NOMAD_INTERNAL_SERVER_ERROR UNKNOWN].freeze

  ERRORS.each do |error|
    define_singleton_method :"error_#{error.downcase}" do
      error
    end
  end

  def self.config
    @config ||= CodeOcean::Config.new(:code_ocean).read[:runner_management] || {}
  end

  def self.headers
    @headers ||= {'Content-Type' => 'application/json', 'Poseidon-Token' => config[:token]}
  end

  def self.sync_environment(environment)
    url = "#{config[:url]}/execution-environments/#{environment.id}"
    connection = Faraday.new nil, ssl: {ca_file: config[:ca_file]}
    response = connection.put url, environment.to_json, headers
    return true if [201, 204].include? response.status

    Rails.logger.warn("Could not create execution environment in Poseidon, got response: #{response.as_json}")
    false
  rescue Faraday::Error => e
    Rails.logger.warn("Could not create execution environment because of Faraday error: #{e.inspect}")
    false
  end

  def self.request_from_management(environment)
    url = "#{config[:url]}/runners"
    body = {
      executionEnvironmentId: environment.id,
      inactivityTimeout: config[:unused_runner_expiration_time].seconds,
    }
    connection = Faraday.new nil, ssl: {ca_file: config[:ca_file]}
    response = connection.post url, body.to_json, headers

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

  def self.parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  rescue JSON::ParserError => e
    # Poseidon should not send invalid json
    raise Runner::Error::UnexpectedResponse.new("Error parsing response from Poseidon: #{e.message}")
  end

  def initialize(runner_id, _environment)
    super
    @allocation_id = runner_id
  end

  def copy_files(files)
    copy = files.map do |file|
      {
        path: file.filepath,
        content: Base64.strict_encode64(file.content),
      }
    end
    url = "#{runner_url}/files"
    body = {copy: copy}
    connection = Faraday.new nil, ssl: {ca_file: self.class.config[:ca_file]}
    response = connection.patch url, body.to_json, self.class.headers
    return if response.status == 204

    Runner.destroy(@allocation_id) if response.status == 400
    self.class.handle_error response
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  end

  def attach_to_execution(command, event_loop)
    websocket_url = execute_command(command)
    socket = Connection.new(websocket_url, self, event_loop)
    yield(socket)
    socket
  end

  def destroy_at_management
    connection = Faraday.new nil, ssl: {ca_file: self.class.config[:ca_file]}
    response = connection.delete runner_url, nil, self.class.headers
    self.class.handle_error response unless response.status == 204
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
  end

  def websocket_header
    {
      tls: {root_cert_file: self.class.config[:ca_file]},
      headers: {'Poseidon-Token' => self.class.config[:token]},
    }
  end

  private

  def execute_command(command)
    url = "#{runner_url}/execute"
    body = {command: command, timeLimit: @execution_environment.permitted_execution_time}
    connection = Faraday.new nil, ssl: {ca_file: self.class.config[:ca_file]}
    response = connection.post url, body.to_json, self.class.headers
    case response.status
      when 200
        response_body = self.class.parse response
        websocket_url = response_body[:websocketUrl]
        if websocket_url.present?
          return websocket_url
        else
          raise Runner::Error::UnexpectedResponse.new('Poseidon did not send a WebSocket URL')
        end
      when 400
        Runner.destroy(@allocation_id)
    end

    self.class.handle_error response
  rescue Faraday::Error => e
    raise Runner::Error::FaradayError.new("Request to Poseidon failed: #{e.inspect}")
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
      data
    end
  end
end
