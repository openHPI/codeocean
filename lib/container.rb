# frozen_string_literal: true

require 'container_connection'

class Container
  BASE_URL = CodeOcean::Config.new(:code_ocean).read[:container_management][:url]
  HEADERS = {"Content-Type" => "application/json"}

  attr_accessor :waiting_time

  def initialize(execution_environment, time_limit = nil)
    url = "#{BASE_URL}/execution-environments/#{execution_environment.id}/containers/create"
    body = {}
    if time_limit
      body[:time_limit] = time_limit
    end
    response = Faraday.post(url, body.to_json, HEADERS)
    response = parse response
    @container_id = response[:id]
  end

  def copy_files(files)
    url = container_url + "/files"
    body = files.map{ |filename, content| { filename => content } }
    Faraday.post(url, body.to_json, HEADERS)
  end

  def copy_submission_files(submission)
    files = {}
    submission.collect_files.each do |file|
      files[file.name] = file.content
    end
    copy_files(files)
  end

  def execute_command(command)
    url = container_url + "/execute"
    response = Faraday.patch(url, {command: command}.to_json, HEADERS)
    response = parse response
    response
  end

  def execute_interactively(command)
    starting_time = Time.now
    websocket_url = execute_command(command)[:websocket_url]
    EventMachine.run do
      socket = ContainerConnection.new(websocket_url)
      yield(self, socket) if block_given?
    end
    Time.now - starting_time # execution time
  end

  def destroy
    Faraday.delete container_url
  end

  def status
    parse(Faraday.get(container_url))[:status].to_sym
  end

  private

  def container_url
    "#{BASE_URL}/containers/#{@container_id}"
  end

  def parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  end
end
