# frozen_string_literal: true

require 'rails_helper'

describe Runner::Strategy::Poseidon do
  let(:runner_id) { FactoryBot.attributes_for(:runner)[:runner_id] }
  let(:execution_environment) { FactoryBot.create :ruby }
  let(:poseidon) { described_class.new(runner_id, execution_environment) }
  let(:error_message) { 'test error message' }
  let(:response_body) { nil }

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

  # All requests except creation handle a NotFound (404) response the same way.
  shared_examples 'NotFound (404) error handling' do
    context 'when Poseidon returns NotFound (404)' do
      let(:response_status) { 404 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::NotFound, /Runner/)
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
        expect { action.call }.to raise_error(Runner::Error::Unknown, /#{response_status}/)
      end
    end
  end

  describe '::request_from_management' do
    let(:action) { -> { described_class.request_from_management(execution_environment) } }
    let!(:request_runner_stub) do
      WebMock
        .stub_request(:post, "#{Runner::BASE_URL}/runners")
        .with(
          body: {executionEnvironmentId: execution_environment.id, inactivityTimeout: Runner::UNUSED_EXPIRATION_TIME},
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
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    context 'when Poseidon returns Ok (200) with invalid JSON' do
      let(:response_body) { '{hello}' }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    include_examples 'BadRequest (400) error handling'
    include_examples 'Unauthorized (401) error handling'

    context 'when Poseidon returns NotFound (404)' do
      let(:response_status) { 404 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::NotFound, /Execution environment/)
      end
    end

    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
  end

  describe '#execute_command' do
    let(:command) { 'ls' }
    let(:action) { -> { poseidon.send(:execute_command, command) } }
    let(:websocket_url) { 'ws://ws.example.com/path/to/websocket' }
    let!(:execute_command_stub) do
      WebMock
        .stub_request(:post, "#{Runner::BASE_URL}/runners/#{runner_id}/execute")
        .with(
          body: {command: command, timeLimit: execution_environment.permitted_execution_time},
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
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    context 'when Poseidon returns Ok (200) with invalid JSON' do
      let(:response_body) { '{hello}' }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    include_examples 'BadRequest (400) error handling'
    include_examples 'BadRequest (400) destroys local runner'
    include_examples 'Unauthorized (401) error handling'
    include_examples 'NotFound (404) error handling'
    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
  end

  describe '#destroy_at_management' do
    let(:action) { -> { poseidon.destroy_at_management } }
    let!(:destroy_stub) do
      WebMock
        .stub_request(:delete, "#{Runner::BASE_URL}/runners/#{runner_id}")
        .to_return(body: response_body, status: response_status)
    end

    context 'when Poseidon returns NoContent (204)' do
      let(:response_status) { 204 }

      it 'deletes the runner from Poseidon' do
        action.call
        expect(destroy_stub).to have_been_requested.once
      end
    end

    include_examples 'Unauthorized (401) error handling'
    include_examples 'NotFound (404) error handling'
    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
  end

  describe '#copy_files' do
    let(:filename) { 'main.py' }
    let(:file_content) { 'print("Hello World!")' }
    let(:action) { -> { poseidon.copy_files({filename => file_content}) } }
    let(:encoded_file_content) { Base64.strict_encode64(file_content) }
    let!(:copy_files_stub) do
      WebMock
        .stub_request(:patch, "#{Runner::BASE_URL}/runners/#{runner_id}/files")
        .with(
          body: {copy: [{path: filename, content: encoded_file_content}]},
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
    include_examples 'NotFound (404) error handling'
    include_examples 'InternalServerError (500) error handling'
    include_examples 'unknown response status error handling'
  end

  describe '#attach_to_execution' do
    # TODO: add more tests here

    let(:command) { 'ls' }
    let(:action) { -> { poseidon.attach_to_execution command } }
    let(:websocket_url) { 'ws://ws.example.com/path/to/websocket' }

    it 'returns the execution time' do
      allow(poseidon).to receive(:execute_command).with(command).and_return(websocket_url)
      allow(EventMachine).to receive(:run)

      starting_time = Time.zone.now
      execution_time = action.call
      test_time = Time.zone.now - starting_time
      expect(execution_time).to be_between(0.0, test_time)
    end
  end
end
