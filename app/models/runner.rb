# frozen_string_literal: true

require 'runner/runner_connection'

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
    runner = Runner.find_or_create_by(user: user, execution_environment: execution_environment)

    return runner if runner.save

    raise RunnerNotAvailableError.new('No runner available')
  end

  def copy_files(files)
    url = "#{runner_url}/files"
    body = {files: files.map {|filename, content| {filepath: filename, content: content} }}
    response = Faraday.patch(url, body.to_json, HEADERS)
    return unless response.status == 404

    # runner has disappeared for some reason
    destroy
    raise RunnerNotAvailableError.new('Runner unavailable')
  end

  def execute_command(command)
    url = "#{runner_url}/execute"
    response = Faraday.post(url, {command: command}.to_json, HEADERS)
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
      socket = RunnerConnection.new(websocket_url)
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
    time_limit = CodeOcean::Config.new(:code_ocean)[:runner_management][:unused_runner_expiration_time]
    body = {executionEnvironmentId: execution_environment.id, timeLimit: time_limit}
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
