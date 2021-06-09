# frozen_string_literal: true

class Runner::Strategy::Poseidon < Runner::Strategy
  HEADERS = {'Content-Type' => 'application/json'}.freeze
  ERRORS = %w[NOMAD_UNREACHABLE NOMAD_OVERLOAD NOMAD_INTERNAL_SERVER_ERROR UNKNOWN].freeze

  ERRORS.each do |error|
    define_singleton_method :"error_#{error.downcase}" do
      error
    end
  end

  def self.request_from_management(environment)
    url = "#{Runner::BASE_URL}/runners"
    body = {executionEnvironmentId: environment.id, inactivityTimeout: Runner::UNUSED_EXPIRATION_TIME}
    response = Faraday.post(url, body.to_json, HEADERS)

    case response.status
      when 200
        response_body = parse response
        runner_id = response_body[:runnerId]
        runner_id.presence || raise(Runner::Error::Unknown.new('Poseidon did not send a runner id'))
      when 404
        raise Runner::Error::NotFound.new('Execution environment not found')
      else
        handle_error response
    end
  end

  def self.handle_error(response)
    case response.status
      when 400
        response_body = parse response
        raise Runner::Error::BadRequest.new(response_body[:message])
      when 401
        raise Runner::Error::Unauthorized.new('Authentication with Poseidon failed')
      when 404
        raise Runner::Error::NotFound.new('Runner not found')
      when 500
        response_body = parse response
        error_code = response_body[:errorCode]
        if error_code == error_nomad_overload
          raise Runner::Error::NotAvailable.new("Poseidon has no runner available (#{error_code}): #{response_body[:message]}")
        else
          raise Runner::Error::InternalServerError.new("Poseidon sent #{response_body[:errorCode]}: #{response_body[:message]}")
        end
      else
        raise Runner::Error::Unknown.new("Poseidon sent unexpected response status code #{response.status}")
    end
  end

  def self.parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  rescue JSON::ParserError => e
    # Poseidon should not send invalid json
    raise Runner::Error::Unknown.new("Error parsing response from Poseidon: #{e.message}")
  end

  def copy_files(files)
    url = "#{runner_url}/files"
    body = {copy: files.map {|filename, content| {path: filename, content: Base64.strict_encode64(content)} }}
    response = Faraday.patch(url, body.to_json, HEADERS)
    self.class.handle_error response unless response.status == 204
  end

  def attach_to_execution(command)
    starting_time = Time.zone.now
    websocket_url = execute_command(command)
    EventMachine.run do
      socket = Runner::Connection.new(websocket_url)
      yield(socket) if block_given?
    end
    Time.zone.now - starting_time # execution duration
  end

  def destroy_at_management
    response = Faraday.delete runner_url
    self.class.handle_error response unless response.status == 204
  end

  private

  def execute_command(command)
    url = "#{runner_url}/execute"
    body = {command: command, timeLimit: @execution_environment.permitted_execution_time}
    response = Faraday.post(url, body.to_json, HEADERS)
    if response.status == 200
      response_body = self.class.parse response
      websocket_url = response_body[:websocketUrl]
      if websocket_url.present?
        return websocket_url
      else
        raise Runner::Error::Unknown.new('Poseidon did not send websocket url')
      end
    end

    self.class.handle_error response
  end

  def runner_url
    "#{Runner::BASE_URL}/runners/#{@runner_id}"
  end
end
