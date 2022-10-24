# frozen_string_literal: true

require 'rails_helper'
require 'pathname'

describe Runner::Strategy::DockerContainerPool do
  let(:runner_id) { attributes_for(:runner)[:runner_id] }
  let(:execution_environment) { create(:ruby) }
  let(:container_pool) { described_class.new(runner_id, execution_environment) }
  let(:docker_container_pool_url) { 'https://localhost:1234' }
  let(:config) { {url: docker_container_pool_url, unused_runner_expiration_time: 180} }
  let(:container) { instance_double(Docker::Container) }

  before do
    allow(described_class).to receive(:config).and_return(config)
    allow(container).to receive(:id).and_return(runner_id)
  end

  # All requests handle a Faraday error the same way.
  shared_examples 'Faraday error handling' do |http_verb|
    it 'raises a runner error' do
      allow(Faraday).to receive(http_verb).and_raise(Faraday::TimeoutError)
      expect { action.call }.to raise_error(Runner::Error::FaradayError)
    end
  end

  describe '::request_from_management' do
    let(:action) { -> { described_class.request_from_management(execution_environment) } }
    let(:response_body) { nil }
    let!(:request_runner_stub) do
      WebMock
        .stub_request(:post, "#{docker_container_pool_url}/docker_container_pool/get_container/#{execution_environment.id}")
        .to_return(body: response_body, status: 200)
    end

    context 'when the DockerContainerPool returns an id' do
      let(:response_body) { {id: runner_id}.to_json }

      it 'successfully requests the DockerContainerPool' do
        action.call
        expect(request_runner_stub).to have_been_requested.once
      end

      it 'returns the received runner id' do
        id = action.call
        expect(id).to eq(runner_id)
      end
    end

    context 'when the DockerContainerPool does not return an id' do
      let(:response_body) { {}.to_json }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::NotAvailable)
      end
    end

    context 'when the DockerContainerPool returns invalid JSON' do
      let(:response_body) { '{hello}' }

      it 'raises an error' do
        expect { action.call }.to raise_error(Runner::Error::UnexpectedResponse)
      end
    end

    include_examples 'Faraday error handling', :post
  end

  describe '#destroy_at_management' do
    let(:action) { -> { container_pool.destroy_at_management } }
    let!(:destroy_runner_stub) do
      WebMock
        .stub_request(:delete, "#{docker_container_pool_url}/docker_container_pool/destroy_container/#{runner_id}")
        .to_return(body: nil, status: 200)
    end

    before { allow(container_pool).to receive(:container).and_return(container) }

    it 'successfully requests the DockerContainerPool' do
      action.call
      expect(destroy_runner_stub).to have_been_requested.once
    end

    include_examples 'Faraday error handling', :delete
  end

  describe '#copy_files' do
    let(:files) { [] }
    let(:action) { -> { container_pool.copy_files(files) } }
    let(:local_path) { Pathname.new('/tmp/container20') }

    before do
      allow(container_pool).to receive(:local_workspace_path).and_return(local_path)
      allow(container_pool).to receive(:clean_workspace)
      allow(FileUtils).to receive(:chmod_R)
    end

    it 'creates the workspace directory' do
      expect(FileUtils).to receive(:mkdir_p).with(local_path)
      container_pool.copy_files(files)
    end

    it 'cleans the workspace' do
      expect(container_pool).to receive(:clean_workspace)
      container_pool.copy_files(files)
    end

    it 'sets permission bits on the workspace' do
      expect(FileUtils).to receive(:chmod_R).with('+rwtX', local_path)
      container_pool.copy_files(files)
    end

    context 'when receiving a normal file' do
      let(:file_content) { 'print("Hello World!")' }
      let(:files) { [build(:file, content: file_content)] }

      it 'writes the file to disk' do
        expect(File).to receive(:write).with(local_path.join(files.first.filepath), file_content)
        container_pool.copy_files(files)
      end

      it 'creates the file inside the workspace' do
        expect(File).to receive(:write).with(local_path.join(files.first.filepath), files.first.content)
        container_pool.copy_files(files)
      end

      it 'raises an error in case of an IOError' do
        allow(File).to receive(:write).and_raise(IOError)
        expect { container_pool.copy_files(files) }.to raise_error(Runner::Error::WorkspaceError, /#{files.first.filepath}/)
      end

      it 'does not create a directory for it' do
        expect(FileUtils).not_to receive(:mkdir_p)
      end

      context 'when the file is inside a directory' do
        let(:directory) { 'temp/dir' }
        let(:files) { [build(:file, path: directory)] }

        before do
          allow(File).to receive(:write)
          allow(FileUtils).to receive(:mkdir_p).with(local_path)
          allow(FileUtils).to receive(:mkdir_p).with(local_path.join(directory))
        end

        it 'cleans the directory path' do
          allow(container_pool).to receive(:local_path).and_call_original
          expect(container_pool).to receive(:local_path).with(directory).and_call_original
          container_pool.copy_files(files)
        end

        it 'creates the directory of the file' do
          expect(FileUtils).to receive(:mkdir_p).with(local_path.join(directory))
          container_pool.copy_files(files)
        end
      end
    end

    context 'when receiving a binary file' do
      let(:files) { [build(:file, :image)] }

      it 'copies the file inside the workspace' do
        expect(File).to receive(:write).with(local_path.join(files.first.filepath), files.first.read)
        container_pool.copy_files(files)
      end
    end

    context 'when receiving multiple files' do
      let(:files) { build_list(:file, 3) }

      it 'creates all files' do
        files.each do |file|
          expect(File).to receive(:write).with(local_path.join(file.filepath), file.content)
        end
        container_pool.copy_files(files)
      end
    end
  end

  describe '#local_workspace_path' do
    before { allow(container_pool).to receive(:container).and_return(container) }

    it 'returns the local part of the mount binding' do
      local_path = 'tmp/container20'
      allow(container).to receive(:json).and_return({HostConfig: {Binds: ["#{local_path}:/workspace"]}}.as_json)
      expect(container_pool.send(:local_workspace_path)).to eq(Pathname.new(local_path))
    end
  end

  describe '#local_path' do
    let(:local_workspace) { Pathname.new('/tmp/workspace') }

    before { allow(container_pool).to receive(:local_workspace_path).and_return(local_workspace) }

    it 'raises an error for relative paths outside of the workspace' do
      expect { container_pool.send(:local_path, '../exercise.py') }.to raise_error(Runner::Error::WorkspaceError, %r{tmp/exercise.py})
    end

    it 'raises an error for absolute paths outside of the workspace' do
      expect { container_pool.send(:local_path, '/test') }.to raise_error(Runner::Error::WorkspaceError, %r{/test})
    end

    it 'removes .. from the path' do
      expect(container_pool.send(:local_path, 'test/../exercise.py')).to eq(Pathname.new('/tmp/workspace/exercise.py'))
    end

    it 'joins the given path with the local workspace path' do
      expect(container_pool.send(:local_path, 'exercise.py')).to eq(Pathname.new('/tmp/workspace/exercise.py'))
    end
  end

  describe '#clean_workspace' do
    let(:local_workspace) { instance_double(Pathname) }

    before { allow(container_pool).to receive(:local_workspace_path).and_return(local_workspace) }

    it 'removes all children of the workspace recursively' do
      children = %w[test.py exercise.rb subfolder].map {|child| Pathname.new(child) }
      allow(local_workspace).to receive(:children).and_return(children)
      expect(FileUtils).to receive(:rm_r).with(children, force: true)
      container_pool.send(:clean_workspace)
    end

    it 'raises an error if the workspace does not exist' do
      allow(local_workspace).to receive(:children).and_raise(Errno::ENOENT)
      expect { container_pool.send(:clean_workspace) }.to raise_error(Runner::Error::WorkspaceError, /not exist/)
    end

    it 'raises an error if it lacks permission for deleting an entry' do
      allow(local_workspace).to receive(:children).and_return(['test.py'])
      allow(FileUtils).to receive(:remove_entry).and_raise(Errno::EPERM)
      expect { container_pool.send(:clean_workspace) }.to raise_error(Runner::Error::WorkspaceError, /Not allowed/)
    end
  end

  describe '#container' do
    it 'raises an error if there is no container for the saved id' do
      allow(Docker::Container).to receive(:get).and_raise(Docker::Error::NotFoundError)
      expect { container_pool.send(:container) }.to raise_error(Runner::Error::RunnerNotFound)
    end

    it 'raises an error if the received container is not running' do
      allow(Docker::Container).to receive(:get).and_return(container)
      allow(container).to receive(:info).and_return({'State' => {'Running' => false}})
      expect { container_pool.send(:container) }.to raise_error(Runner::Error::RunnerNotFound)
    end

    it 'returns the received container' do
      allow(Docker::Container).to receive(:get).and_return(container)
      allow(container).to receive(:info).and_return({'State' => {'Running' => true}})
      expect(container_pool.send(:container)).to eq(container)
    end

    it 'does not request a container if one is saved' do
      container_pool.instance_variable_set(:@container, container)
      expect(Docker::Container).not_to receive(:get)
      container_pool.send(:container)
    end
  end

  describe '#attach_to_execution' do
    # TODO: add tests here

    let(:command) { 'ls' }
    let(:event_loop) { Runner::EventLoop.new }
    let(:action) { -> { container_pool.attach_to_execution(command, event_loop) } }
    let(:websocket_url) { 'ws://ws.example.com/path/to/websocket' }
  end
end
