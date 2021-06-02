# frozen_string_literal: true

class Runner < ApplicationRecord
  BASE_URL = CodeOcean::Config.new(:code_ocean).read[:runner_management][:url]
  HEADERS = {'Content-Type' => 'application/json'}.freeze
  UNUSED_EXPIRATION_TIME = CodeOcean::Config.new(:code_ocean).read[:runner_management][:unused_runner_expiration_time].seconds

  belongs_to :execution_environment
  belongs_to :user, polymorphic: true

  before_create :new_runner
  before_destroy :destroy_runner

  validates :execution_environment, presence: true
  validates :user, presence: true

  def self.for(user, exercise)
    execution_environment = ExecutionEnvironment.find(exercise.execution_environment_id)
    runner = find_or_create_by(user: user, execution_environment: execution_environment)

    return runner if runner.save

    raise RunnerNotAvailableError.new('No runner available')
  end

  def copy_files(files)
    url = "#{runner_url}/files"
    body = {copy: files.map {|filename, content| {path: filename, content: Base64.strict_encode64(content)} }}
    response = Faraday.patch(url, body.to_json, HEADERS)
    return unless response.status == 404

    # runner has disappeared for some reason
    destroy
    raise RunnerNotAvailableError.new('Runner unavailable')
  end

  def execute_command(command)
    url = "#{runner_url}/execute"
    body = {command: command, timeLimit: execution_environment.permitted_execution_time}
    response = Faraday.post(url, body.to_json, HEADERS)
    if response.status == 404
      # runner has disappeared for some reason
      destroy
      raise RunnerNotAvailableError.new('Runner unavailable')
    end
    parse response
  end

  def execute_interactively(command)
    starting_time = Time.zone.now
    websocket_url = execute_command(command)[:websocketUrl]
    EventMachine.run do
      socket = Runner::Connection.new(websocket_url)
      yield(self, socket) if block_given?
    end
    Time.zone.now - starting_time # execution time
  end

  def destroy_runner
    Faraday.delete runner_url
  end

  def status
    # TODO: return actual state retrieved via websocket
    :timeouted
  end

  private

  def new_runner
    url = "#{BASE_URL}/runners"
    body = {executionEnvironmentId: execution_environment.id, inactivityTimeout: UNUSED_EXPIRATION_TIME}
    response = Faraday.post(url, body.to_json, HEADERS)
    response_body = parse response
    self.runner_id = response_body[:runnerId]
    throw :abort unless response.status == 200
  end

  def runner_url
    "#{BASE_URL}/runners/#{runner_id}"
  end

  def parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  end
end
