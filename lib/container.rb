# frozen_string_literal: true

class Container
  BASE_URL = "http://192.168.178.53:5000"

  attr_accessor :socket

  def initialize(execution_environment)
    url = "#{BASE_URL}/execution-environments/#{execution_environment.id}/containers/create"
    response = Faraday.post url
    response = parse response
    @container_id = response[:id]
  end

  def copy_files(files)
    url = container_url + "/files"
    payload = files.map{ |filename, content| { filename => content } }
    Faraday.post(url, payload.to_json)
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
    response = Faraday.patch(url, {command: command}.to_json, "Content-Type" => "application/json")
    response = parse response
    response
  end

  def execute_command_interactively(command)
    websocket_url = execute_command(command)[:websocket_url]
    @socket = Faye::WebSocket::Client.new websocket_url
  end

  def destroy
    Faraday.delete container_url
  end

  private

  def container_url
    "#{BASE_URL}/containers/#{@container_id}"
  end

  def parse(response)
    JSON.parse(response.body).deep_symbolize_keys
  end
end
