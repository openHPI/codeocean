# frozen_string_literal: true

class Runner < ApplicationRecord
  BASE_URL = CodeOcean::Config.new(:code_ocean).read[:runner_management][:url]
  HEADERS = {'Content-Type' => 'application/json'}.freeze
  UNUSED_EXPIRATION_TIME = CodeOcean::Config.new(:code_ocean).read[:runner_management][:unused_runner_expiration_time].seconds
  ERRORS = %w[NOMAD_UNREACHABLE NOMAD_OVERLOAD NOMAD_INTERNAL_SERVER_ERROR UNKNOWN].freeze

  ERRORS.each do |error|
    define_singleton_method :"error_#{error.downcase}" do
      error
    end
  end

  belongs_to :execution_environment
  belongs_to :user, polymorphic: true

  before_validation :request_remotely

  validates :execution_environment, :user, :runner_id, presence: true

  def self.for(user, exercise)
    execution_environment = ExecutionEnvironment.find(exercise.execution_environment_id)
    runner = find_or_create_by(user: user, execution_environment: execution_environment)

    unless runner.persisted?
      # runner was not saved in the database (was not valid)
      raise Runner::Error::InternalServerError.new("Provided runner could not be saved: #{runner.errors.inspect}")
    end

    runner
  end

  def copy_files(files)
    url = "#{runner_url}/files"
    body = {copy: files.map {|filename, content| {path: filename, content: Base64.strict_encode64(content)} }}
    response = Faraday.patch(url, body.to_json, HEADERS)
    handle_error response unless response.status == 204
  end

  def execute_command(command)
    url = "#{runner_url}/execute"
    body = {command: command, timeLimit: execution_environment.permitted_execution_time}
    response = Faraday.post(url, body.to_json, HEADERS)
    if response.status == 200
      response_body = parse response
      websocket_url = response_body[:websocketUrl]
      if websocket_url.present?
        return websocket_url
      else
        raise Runner::Error::Unknown.new('Runner management sent unexpected response')
      end
    end

    handle_error response
  end

  def execute_interactively(command)
    starting_time = Time.zone.now
    websocket_url = execute_command(command)
    EventMachine.run do
      socket = Runner::Connection.new(websocket_url)
      yield(self, socket) if block_given?
    end
    Time.zone.now - starting_time # execution time
  end

  # This method is currently not used.
  # This does *not* destroy the ActiveRecord model.
  def destroy_remotely
    response = Faraday.delete runner_url
    return if response.status == 204

    if response.status == 404
      raise Runner::Error::NotFound.new('Runner not found')
    else
      handle_error response
    end
  end

  private

  def request_remotely
    return if runner_id.present?

    url = "#{BASE_URL}/runners"
    body = {executionEnvironmentId: execution_environment.id, inactivityTimeout: UNUSED_EXPIRATION_TIME}
    response = Faraday.post(url, body.to_json, HEADERS)

    case response.status
      when 200
        response_body = parse response
        runner_id = response_body[:runnerId]
        throw(:abort) if runner_id.blank?
        self.runner_id = response_body[:runnerId]
      when 404
        raise Runner::Error::NotFound.new('Execution environment not found')
      else
        handle_error response
    end
  end

  def handle_error(response)
    case response.status
      when 400
        response_body = parse response
        raise Runner::Error::BadRequest.new(response_body[:message])
      when 401
        raise Runner::Error::Unauthorized.new('Authentication with runner management failed')
      when 404
        # The runner does not exist in the runner management (e.g. due to an inactivity timeout).
        # Delete the runner model in this case as it can not be used anymore.
        destroy
        raise Runner::Error::NotFound.new('Runner not found')
      when 500
        response_body = parse response
        error_code = response_body[:errorCode]
        if error_code == Runner.error_nomad_overload
          raise Runner::Error::NotAvailable.new("No runner available (#{error_code}): #{response_body[:message]}")
        else
          raise Runner::Error::InternalServerError.new("#{response_body[:errorCode]}: #{response_body[:message]}")
        end
      else
        raise Runner::Error::Unknown.new('Runner management sent unexpected response')
    end
  end

  def runner_url
    "#{BASE_URL}/runners/#{runner_id}"
  end

  def parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  rescue JSON::ParserError => e
    # the runner management should not send invalid json
    raise Runner::Error::Unknown.new("Error parsing response from runner management: #{e.message}")
  end
end
