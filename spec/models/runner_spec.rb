# frozen_string_literal: true

require 'rails_helper'

describe Runner do
  let(:runner) { FactoryBot.create :runner }
  let(:runner_id) { runner.runner_id }
  let(:error_message) { 'test error message' }
  let(:response_body) { nil }
  let(:user) { FactoryBot.build :external_user }
  let(:execution_environment) { FactoryBot.create :ruby }

  # All requests handle a BadRequest (400) response the same way.
  shared_examples 'BadRequest (400) error handling' do
    let(:response_body) { {message: error_message}.to_json }
    let(:response_status) { 400 }

    it 'raises an error' do
      expect { action.call }.to raise_error(Runner::Error::BadRequest, /#{error_message}/)
    end
  end

  # All requests handle a Unauthorized (401) response the same way.
  shared_examples 'Unauthorized (401) error handling' do
    let(:response_status) { 401 }

    it 'raises an error' do
      expect { action.call }.to raise_error(Runner::Error::Unauthorized)
    end
  end

  # All requests except creation and destruction handle a NotFound (404) response the same way.
  shared_examples 'NotFound (404) error handling' do
    let(:response_status) { 404 }

    it 'raises an error' do
      expect { action.call }.to raise_error(Runner::Error::NotFound, /Runner/)
    end

    it 'destroys the runner locally' do
      expect { action.call }.to change(described_class, :count).by(-1)
        .and raise_error(Runner::Error::NotFound)
    end
  end

  # All requests handle an InternalServerError (500) response the same way.
  shared_examples 'InternalServerError (500) error handling' do
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

  # All requests handle an unknown response status the same way.
  shared_examples 'unknown response status error handling' do
    let(:response_status) { 1337 }

    it 'raises an error' do
      expect { action.call }.to raise_error(Runner::Error::Unknown)
    end
  end

  describe 'attribute validation' do
    let(:runner) { FactoryBot.create :runner }

    it 'validates the presence of the runner id' do
      described_class.skip_callback(:validation, :before, :request_remotely)
      runner.update(runner_id: nil)
      expect(runner.errors[:runner_id]).to be_present
      described_class.set_callback(:validation, :before, :request_remotely)
    end

    it 'validates the presence of an execution environment' do
      runner.update(execution_environment: nil)
      expect(runner.errors[:execution_environment]).to be_present
    end

    it 'validates the presence of a user' do
      runner.update(user: nil)
      expect(runner.errors[:user]).to be_present
    end
  end

  describe 'creation' do
    let(:action) { -> { described_class.create(user: user, execution_environment: execution_environment) } }
    let!(:create_stub) do
      WebMock
        .stub_request(:post, "#{Runner::BASE_URL}/runners")
        .with(
          body: {executionEnvironmentId: execution_environment.id, inactivityTimeout: Runner::UNUSED_EXPIRATION_TIME},
          headers: {'Content-Type' => 'application/json'}
        )
        .to_return(body: response_body, status: response_status)
    end

    context 'when a runner is created' do
      let(:response_body) { {runnerId: runner_id}.to_json }
      let(:response_status) { 200 }

      it 'requests a runner from the runner management' do
        action.call
        expect(create_stub).to have_been_requested.once
      end

      it 'does not call the runner management again when updating' do
        runner = action.call
        runner.runner_id = 'another_id'
        successfully_saved = runner.save
        expect(successfully_saved).to be_truthy
        expect(create_stub).to have_been_requested.once
      end
    end

    context 'when the runner management returns Ok (200) with an id' do
      let(:response_body) { {runnerId: runner_id}.to_json }
      let(:response_status) { 200 }

      it 'sets the runner id according to the response' do
        runner = action.call
        expect(runner.runner_id).to eq(runner_id)
        expect(runner).to be_persisted
      end
    end

    context 'when the runner management returns Ok (200) without an id' do
      let(:response_body) { {}.to_json }
      let(:response_status) { 200 }

      it 'does not save the runner' do
        runner = action.call
        expect(runner).not_to be_persisted
      end
    end

    context 'when the runner management returns Ok (200) with invalid JSON' do
      let(:response_body) { '{hello}' }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    context 'when the runner management returns BadRequest (400)' do
      include_examples 'BadRequest (400) error handling'
    end

    context 'when the runner management returns Unauthorized (401)' do
      include_examples 'Unauthorized (401) error handling'
    end

    context 'when the runner management returns NotFound (404)' do
      let(:response_status) { 404 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::NotFound, /Execution environment/)
      end
    end

    context 'when the runner management returns InternalServerError (500)' do
      include_examples 'InternalServerError (500) error handling'
    end

    context 'when the runner management returns an unknown response status' do
      include_examples 'unknown response status error handling'
    end
  end

  describe 'execute command' do
    let(:command) { 'ls' }
    let(:action) { -> { runner.execute_command(command) } }
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

    context 'when #execute_command is called' do
      let(:response_status) { 200 }
      let(:response_body) { {websocketUrl: websocket_url}.to_json }

      it 'schedules an execution in the runner management' do
        action.call
        expect(execute_command_stub).to have_been_requested.once
      end
    end

    context 'when the runner management returns Ok (200) with a websocket url' do
      let(:response_status) { 200 }
      let(:response_body) { {websocketUrl: websocket_url}.to_json }

      it 'returns the url' do
        url = action.call
        expect(url).to eq(websocket_url)
      end
    end

    context 'when the runner management returns Ok (200) without a websocket url' do
      let(:response_body) { {}.to_json }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    context 'when the runner management returns Ok (200) with invalid JSON' do
      let(:response_body) { '{hello}' }
      let(:response_status) { 200 }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::Unknown)
      end
    end

    context 'when the runner management returns BadRequest (400)' do
      include_examples 'BadRequest (400) error handling'
    end

    context 'when the runner management returns Unauthorized (401)' do
      include_examples 'Unauthorized (401) error handling'
    end

    context 'when the runner management returns NotFound (404)' do
      include_examples 'NotFound (404) error handling'
    end

    context 'when the runner management returns InternalServerError (500)' do
      include_examples 'InternalServerError (500) error handling'
    end

    context 'when the runner management returns an unknown response status' do
      include_examples 'unknown response status error handling'
    end
  end

  describe 'destruction' do
    let(:action) { -> { runner.destroy_remotely } }
    let(:response_status) { 204 }
    let!(:destroy_stub) do
      WebMock
        .stub_request(:delete, "#{Runner::BASE_URL}/runners/#{runner_id}")
        .to_return(body: response_body, status: response_status)
    end

    it 'deletes the runner from the runner management' do
      action.call
      expect(destroy_stub).to have_been_requested.once
    end

    it 'does not destroy the runner locally' do
      expect { action.call }.not_to change(described_class, :count)
    end

    context 'when the runner management returns NoContent (204)' do
      it 'does not raise an error' do
        expect { action.call }.not_to raise_error
      end
    end

    context 'when the runner management returns Unauthorized (401)' do
      include_examples 'Unauthorized (401) error handling'
    end

    context 'when the runner management returns NotFound (404)' do
      let(:response_status) { 404 }

      it 'raises an exception' do
        expect { action.call }.to raise_error(Runner::Error::NotFound, /Runner/)
      end
    end

    context 'when the runner management returns InternalServerError (500)' do
      include_examples 'InternalServerError (500) error handling'
    end

    context 'when the runner management returns an unknown response status' do
      include_examples 'unknown response status error handling'
    end
  end

  describe 'copy files' do
    let(:filename) { 'main.py' }
    let(:file_content) { 'print("Hello World!")' }
    let(:action) { -> { runner.copy_files({filename => file_content}) } }
    let(:encoded_file_content) { Base64.strict_encode64(file_content) }
    let(:response_status) { 204 }
    let!(:copy_files_stub) do
      WebMock
        .stub_request(:patch, "#{Runner::BASE_URL}/runners/#{runner_id}/files")
        .with(
          body: {copy: [{path: filename, content: encoded_file_content}]},
          headers: {'Content-Type' => 'application/json'}
        )
        .to_return(body: response_body, status: response_status)
    end

    it 'sends the files to the runner management' do
      action.call
      expect(copy_files_stub).to have_been_requested.once
    end

    context 'when the runner management returns NoContent (204)' do
      let(:response_status) { 204 }

      it 'does not raise an error' do
        expect { action.call }.not_to raise_error
      end
    end

    context 'when the runner management returns BadRequest (400)' do
      include_examples 'BadRequest (400) error handling'
    end

    context 'when the runner management returns Unauthorized (401)' do
      include_examples 'Unauthorized (401) error handling'
    end

    context 'when the runner management returns NotFound (404)' do
      include_examples 'NotFound (404) error handling'
    end

    context 'when the runner management returns InternalServerError (500)' do
      include_examples 'InternalServerError (500) error handling'
    end

    context 'when the runner management returns an unknown response status' do
      include_examples 'unknown response status error handling'
    end
  end
end
