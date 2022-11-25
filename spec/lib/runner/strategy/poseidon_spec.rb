# frozen_string_literal: true

require 'rails_helper'

describe Runner::Strategy::Poseidon do
  let(:runner_id) { attributes_for(:runner)[:runner_id] }
  let(:execution_environment) { create(:ruby) }
  let(:poseidon) { described_class.new(runner_id, execution_environment) }
  let(:error_message) { 'test error message' }
  let(:response_body) { nil }

  let(:codeocean_config) { instance_double(CodeOcean::Config) }
  let(:runner_management_config) { {runner_management: {enabled: true, strategy: :poseidon, url: 'https://runners.example.org', unused_runner_expiration_time: 180}} }

  before do
    # Ensure to reset the memorized helper
    Runner.instance_variable_set :@strategy_class, nil
    allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
    allow(codeocean_config).to receive(:read).and_return(runner_management_config)
  end

  # All requests handle a BadRequest (400) response the same way.
  shared_examples 'BadRequest (400) error handling' do
    context 'when Poseidon returns BadRequest (400)' do
      let(:response_body) { {message: error_message}.to_json }
      let(:response_status) { 400 }

      it 'raises an error' do
        allow(Runner).to receive(:destroy).with(runner_id)
        expect { action.call }.to raise_error(Runner::Error::BadRequest, /#{error_message}/)
      end
    end
  end

  # Only #copy_files and #execute_command destroy the runner locally in case
  # of a BadRequest (400) response.
  shared_examples 'BadRequest (400) destroys local runner' do
    context 'when Poseidon returns BadRequest (400)' do
      let(:response_body) { {message: error_message}.to_json }
      let(:response_status) { 400 }

      it 'destroys the runner locally' do
        expect(Runner).to receive(:destroy).with(runner_id)
        expect { action.call }.to raise_error(Runner::Error::BadRequest)
      end
    end
  end

  # All requests handle a Unauthorized (401) response the same way.
  shared_examples 'Unauthorized (401) error handling' do
    context 'when Poseidon returns Unauthorized (401)' do
      let(:response_status) { 401 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::Unauthorized)
      end
    end
  end

  # All runner requests except creation handle a Gone (410) response the same way.
  shared_examples 'Gone (410) error handling' do
    context 'when Poseidon returns NotFound (410)' do
      let(:response_status) { 410 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::RunnerNotFound)
      end
    end
  end

  # All requests handle an InternalServerError (500) response the same way.
  shared_examples 'InternalServerError (500) error handling' do
    context 'when Poseidon returns InternalServerError (500)' do
      shared_examples 'InternalServerError (500) with error code' do |error_code, error_class|
        let(:response_status) { 500 }
        let(:response_body) { {message: error_message, errorCode: error_code}.to_json }

        it 'raises an error' do
          expect { action.call }.to raise_error(error_class) do |error|
            expect(error.message).to match(/#{error_message}/)
            expect(error.message).to match(/#{error_code}/)
          end
        end
      end

      context 'when error code is nomad overload' do
        include_examples(
          'InternalServerError (500) with error code',
          described_class.error_nomad_overload, Runner::Error::NotAvailable
        )
      end

      context 'when error code is not nomad overload' do
        include_examples(
          'InternalServerError (500) with error code',
          described_class.error_unknown, Runner::Error::InternalServerError
        )
      end
    end
  end

  # All requests handle an unknown response status the same way.
  shared_examples 'unknown response status error handling' do
    context 'when Poseidon returns an unknown response status' do
      let(:response_status) { 1337 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::UnexpectedResponse, /#{response_status}/)
      end
    end
  end

  # All requests handle a Faraday error the same way.
  shared_examples 'Faraday error handling' do
    context 'when Faraday throws an error' do
      # The response status is not needed in this context but the describes block this context is embedded
      # into expect this variable to be set in order to properly stub requests to the runner management.
      let(:response_status) { -1 }

      it 'raises an error' do
        faraday_connection = instance_double Faraday::Connection
        allow(described_class).to receive(:http_connection).and_return(faraday_connection)
        %i[post patch delete].each {|message| allow(faraday_connection).to receive(message).and_raise(Faraday::TimeoutError) }
        expect { action.call }.to raise_error(Runner::Error::FaradayError)
      end
    end
  end

  describe '::sync_environment' do
    let(:action) { -> { described_class.sync_environment(execution_environment) } }
    let(:execution_environment) { create(:ruby) }

    it 'makes the correct request to Poseidon' do
      faraday_connection = instance_double Faraday::Connection
      allow(described_class).to receive(:http_connection).and_return(faraday_connection)
      allow(faraday_connection).to receive(:put).and_return(Faraday::Response.new(status: 201))
      action.call
      expect(faraday_connection).to have_received(:put) do |url, body|
        expect(url).to match(%r{execution-environments/#{execution_environment.id}\z})
        expect(body).to eq(execution_environment.to_json)
      end
    end

    shared_examples 'returns true when the api request was successful' do |status|
      it "returns true on status #{status}" do
        faraday_connection = instance_double Faraday::Connection
        allow(described_class).to receive(:http_connection).and_return(faraday_connection)
        allow(faraday_connection).to receive(:put).and_return(Faraday::Response.new(status:))
        expect(action.call).to be_truthy
      end
    end

    shared_examples 'returns false when the api request failed' do |status|
      it "raises an exception on status #{status}" do
        faraday_connection = instance_double Faraday::Connection
        allow(described_class).to receive(:http_connection).and_return(faraday_connection)
        allow(faraday_connection).to receive(:put).and_return(Faraday::Response.new(status:))
        expect { action.call }.to raise_exception Runner::Error::UnexpectedResponse
      end
    end

    [201, 204].each do |status|
      include_examples 'returns true when the api request was successful', status
    end

    [400, 500].each do |status|
      include_examples 'returns false when the api request failed', status
    end

    it 'raises an exception if Faraday raises an error' do
      faraday_connection = instance_double Faraday::Connection
      allow(described_class).to receive(:http_connection).and_return(faraday_connection)
      allow(faraday_connection).to receive(:put).and_raise(Faraday::TimeoutError)
      expect { action.call }.to raise_exception Runner::Error::FaradayError
    end
  end

  describe '::request_from_management' do
    let(:action) { -> { described_class.request_from_management(execution_environment) } }
    let!(:request_runner_stub) do
      WebMock
        .stub_request(:post, "#{described_class.config[:url]}/runners")
        .with(
          body: {
            executionEnvironmentId: execution_environment.id,
            inactivityTimeout: described_class.config[:unused_runner_expiration_time].seconds,
          },
          headers: {'Content-Type' => 'application/json'}
        )
        .to_return(body: response_body, status: response_status)
    end

    context 'when Poseidon returns Ok (200) with an id' do
      let(:response_body) { {runnerId: runner_id}.to_json }
      let(:response_status) { 200 }

      it 'successfully requests Poseidon' do
        action.call
        expect(request_runner_stub).to have_been_requested.once
      end

      it 'returns the received runner id' do
        id = action.call
        expect(id).to eq(runner_id)
      end
    end

    context 'when Poseidon returns Ok (200) without an id' do
      let(:response_body) { {}.to_json }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::UnexpectedResponse)
      end
    end

    context 'when Poseidon returns Ok (200) with invalid JSON' do
      let(:response_body) { '{hello}' }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::UnexpectedResponse)
      end
    end

    include_examples 'BadRequest (400) error handling'
    include_examples 'Unauthorized (401) error handling'

    context 'when Poseidon returns NotFound (404)' do
      let(:response_status) { 404 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::EnvironmentNotFound)
      end
    end

    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
    include_examples 'Faraday error handling'
  end

  describe '#execute_command' do
    let(:command) { 'ls' }
    let(:action) { -> { poseidon.send(:execute_command, command) } }
    let(:websocket_url) { 'ws://ws.example.com/path/to/websocket' }
    let!(:execute_command_stub) do
      WebMock
        .stub_request(:post, "#{described_class.config[:url]}/runners/#{runner_id}/execute")
        .with(
          body: {
            command:,
            timeLimit: execution_environment.permitted_execution_time,
            privilegedExecution: execution_environment.privileged_execution,
          },
          headers: {'Content-Type' => 'application/json'}
        )
        .to_return(body: response_body, status: response_status)
    end

    context 'when Poseidon returns Ok (200) with a websocket url' do
      let(:response_status) { 200 }
      let(:response_body) { {websocketUrl: websocket_url}.to_json }

      it 'schedules an execution in Poseidon' do
        action.call
        expect(execute_command_stub).to have_been_requested.once
      end

      it 'returns the url' do
        url = action.call
        expect(url).to eq(websocket_url)
      end
    end

    context 'when Poseidon returns Ok (200) without a websocket url' do
      let(:response_body) { {}.to_json }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::UnexpectedResponse)
      end
    end

    context 'when Poseidon returns Ok (200) with invalid JSON' do
      let(:response_body) { '{hello}' }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::UnexpectedResponse)
      end
    end

    include_examples 'BadRequest (400) error handling'
    include_examples 'Unauthorized (401) error handling'
    include_examples 'Gone (410) error handling'
    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
    include_examples 'Faraday error handling'
  end

  describe '#destroy_at_management' do
    let(:action) { -> { poseidon.destroy_at_management } }
    let!(:destroy_stub) do
      WebMock
        .stub_request(:delete, "#{described_class.config[:url]}/runners/#{runner_id}")
        .to_return(body: response_body, status: response_status)
    end

    context 'when Poseidon returns NoContent (204)' do
      let(:response_status) { 204 }

      it 'deletes the runner from Poseidon' do
        action.call
        expect(destroy_stub).to have_been_requested.once
      end
    end

    context 'when Poseidon returns Gone (410)' do
      let(:response_status) { 410 }

      it 'raises an error' do
        expect { action.call }.not_to raise_error
      end
    end

    include_examples 'Unauthorized (401) error handling'
    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
    include_examples 'Faraday error handling'
  end

  describe '#copy_files' do
    let(:file_content) { 'print("Hello World!")' }
    let(:file) { build(:file, content: file_content) }
    let(:action) { -> { poseidon.copy_files([file]) } }
    let(:encoded_file_content) { Base64.strict_encode64(file.content) }
    let!(:copy_files_stub) do
      WebMock
        .stub_request(:patch, "#{described_class.config[:url]}/runners/#{runner_id}/files")
        .with(
          body: {copy: [{path: file.filepath, content: encoded_file_content}], delete: ['./*']},
          headers: {'Content-Type' => 'application/json'}
        )
        .to_return(body: response_body, status: response_status)
    end

    context 'when Poseidon returns NoContent (204)' do
      let(:response_status) { 204 }

      it 'sends the files to Poseidon' do
        action.call
        expect(copy_files_stub).to have_been_requested.once
      end
    end

    include_examples 'BadRequest (400) error handling'
    include_examples 'BadRequest (400) destroys local runner'
    include_examples 'Unauthorized (401) error handling'
    include_examples 'Gone (410) error handling'
    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
    include_examples 'Faraday error handling'
  end

  describe '#attach_to_execution' do
    # TODO: add tests here

    let(:command) { 'ls' }
    let(:event_loop) { Runner::EventLoop.new }
    let(:action) { -> { poseidon.attach_to_execution(command, event_loop) } }
    let(:websocket_url) { 'ws://ws.example.com/path/to/websocket' }
  end
end
