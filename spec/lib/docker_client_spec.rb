require 'rails_helper'
require 'seeds_helper'

describe DockerClient, docker: true do
  let(:command) { 'whoami' }
  let(:docker_client) { DockerClient.new(execution_environment: FactoryGirl.build(:ruby), user: FactoryGirl.build(:admin)) }
  let(:image) { double }
  let(:submission) { FactoryGirl.create(:submission) }
  let(:workspace_path) { '/tmp' }

  describe '#bound_folders' do
    context 'when executing a submission' do
      before(:each) { docker_client.instance_variable_set(:@submission, submission) }

      it 'returns a submission-specific mapping' do
        mapping = docker_client.send(:bound_folders).first
        expect(mapping).to include(submission.id.to_s)
        expect(mapping).to end_with(DockerClient::CONTAINER_WORKSPACE_PATH)
      end
    end

    context 'when executing a single command' do
      it 'returns an empty mapping' do
        expect(docker_client.send(:bound_folders)).to eq([])
      end
    end
  end

  describe '.check_availability!' do
    context 'when a socket error occurs' do
      it 'raises an error' do
        expect(Docker).to receive(:version).and_raise(Excon::Errors::SocketError.new(StandardError.new))
        expect { DockerClient.check_availability! }.to raise_error(DockerClient::Error)
      end
    end

    context 'when a timeout occurs' do
      it 'raises an error' do
        expect(Docker).to receive(:version).and_raise(Timeout::Error)
        expect { DockerClient.check_availability! }.to raise_error(DockerClient::Error)
      end
    end
  end

  describe '#clean_workspace' do
    it 'removes the submission-specific directory' do
      expect(docker_client).to receive(:local_workspace_path).and_return(workspace_path)
      expect(FileUtils).to receive(:rm_rf).with(workspace_path)
      docker_client.send(:clean_workspace)
    end
  end

  describe '#create_container' do
    let(:image_tag) { 'tag' }
    before(:each) { docker_client.instance_variable_set(:@image, image) }

    it 'creates a container' do
      expect(image).to receive(:info).and_return({'RepoTags' => [image_tag]})
      expect(Docker::Container).to receive(:create).with('Cmd' => command, 'Image' => image_tag)
      docker_client.send(:create_container, command: command)
    end
  end

  describe '#create_workspace' do
    before(:each) { docker_client.instance_variable_set(:@submission, submission) }

    it 'creates submission-specific directories' do
      expect(docker_client).to receive(:local_workspace_path).at_least(:once).and_return(workspace_path)
      expect(Dir).to receive(:mkdir).at_least(:once)
      docker_client.send(:create_workspace)
    end
  end

  describe '#create_workspace_file' do
    let(:file) { FactoryGirl.build(:file, content: 'puts 42') }
    let(:file_path) { File.join(workspace_path, file.name_with_extension) }

    it 'creates a file' do
      expect(docker_client).to receive(:local_workspace_path).and_return(workspace_path)
      docker_client.send(:create_workspace_file, file: file)
      expect(File.exist?(file_path)).to be true
      expect(File.new(file_path, 'r').read).to eq(file.content)
      File.delete(file_path)
    end
  end

  describe '.destroy_container' do
    let(:container) { docker_client.send(:create_container, {command: command}) }
    after(:each) { DockerClient.destroy_container(container) }

    it 'stops the container' do
      expect(container).to receive(:stop).and_return(container)
    end

    it 'kills the container' do
      expect(container).to receive(:kill)
    end

    it 'releases allocated ports' do
      expect(container).to receive(:json).at_least(:once).and_return({'HostConfig' => {'PortBindings' => {foo: [{'HostPort' => '42'}]}}})
      docker_client.send(:start_container, container)
      expect(PortPool).to receive(:release)
    end
  end

  describe '#execute_command' do
    after(:each) { docker_client.send(:execute_command, command) }

    it 'creates a container' do
      expect(docker_client).to receive(:create_container).with(command: ['bash', '-c', command]).and_call_original
    end

    it 'starts the container' do
      expect(docker_client).to receive(:start_container)
    end
  end

  describe '#execute_in_workspace' do
    let(:block) { Proc.new do; end }
    let(:execute_in_workspace) { docker_client.send(:execute_in_workspace, submission, &block) }
    after(:each) { execute_in_workspace }

    it 'creates the workspace' do
      expect(docker_client).to receive(:create_workspace)
    end

    it 'calls the block' do
      expect(block).to receive(:call)
    end

    it 'cleans the workspace' do
      expect(docker_client).to receive(:clean_workspace)
    end
  end

  describe '#execute_run_command' do
    let(:block) { Proc.new {} }
    let(:filename) { submission.exercise.files.detect { |file| file.role == 'main_file' }.name_with_extension }
    after(:each) { docker_client.send(:execute_run_command, submission, filename, &block) }

    it 'is executed in the workspace' do
      expect(docker_client).to receive(:execute_in_workspace)
    end

    it 'executes the run command' do
      expect(docker_client).to receive(:execute_command).with(kind_of(String), &block)
    end
  end

  describe '#execute_test_command' do
    let(:filename) { submission.exercise.files.detect { |file| file.role == 'teacher_defined_test' }.name_with_extension }
    after(:each) { docker_client.send(:execute_test_command, submission, filename) }

    it 'is executed in the workspace' do
      expect(docker_client).to receive(:execute_in_workspace)
    end

    it 'executes the test command' do
      expect(docker_client).to receive(:execute_command).with(kind_of(String))
    end
  end

  describe '.initialize_environment' do
    let(:config) { {connection_timeout: 3, host: 'tcp://8.8.8.8:2375', workspace_root: '/'} }

    context 'with complete configuration' do
      before(:each) { expect(DockerClient).to receive(:config).at_least(:once).and_return(config) }

      it 'does not raise an error' do
        expect { DockerClient.initialize_environment }.not_to raise_error
      end
    end

    context 'with incomplete configuration' do
      before(:each) { expect(DockerClient).to receive(:config).at_least(:once).and_return({}) }

      it 'raises an error' do
        expect { DockerClient.initialize_environment }.to raise_error(DockerClient::Error)
      end
    end
  end

  describe '#local_workspace_path' do
    before(:each) { docker_client.instance_variable_set(:@submission, submission) }

    it 'includes the correct workspace root' do
      expect(docker_client.send(:local_workspace_path)).to start_with(DockerClient::LOCAL_WORKSPACE_ROOT.to_s)
    end

    it 'is submission-specific' do
      expect(docker_client.send(:local_workspace_path)).to end_with(submission.id.to_s)
    end
  end

  describe '#remote_workspace_path' do
    before(:each) { docker_client.instance_variable_set(:@submission, submission) }

    it 'includes the correct workspace root' do
      expect(docker_client.send(:remote_workspace_path)).to start_with(DockerClient.config[:workspace_root])
    end

    it 'is submission-specific' do
      expect(docker_client.send(:remote_workspace_path)).to end_with(submission.id.to_s)
    end
  end

  describe '#start_container' do
    let(:container) { docker_client.send(:create_container, command: command) }
    let(:start_container) { docker_client.send(:start_container, container) }

    it 'configures bound folders' do
      expect(container).to receive(:start).with(hash_including('Binds' => kind_of(Array))).and_call_original
      start_container
    end

    it 'configures bound ports' do
      expect(container).to receive(:start).with(hash_including('PortBindings' => kind_of(Hash))).and_call_original
      start_container
    end

    it 'starts the container' do
      expect(container).to receive(:start).and_call_original
      start_container
    end

    it 'waits for the container to terminate' do
      expect(container).to receive(:wait).with(kind_of(Numeric)).and_call_original
      start_container
    end

    context 'when a timeout occurs' do
      before(:each) { expect(container).to receive(:wait).and_raise(Docker::Error::TimeoutError) }

      it 'kills the container' do
        expect(container).to receive(:kill)
        start_container
      end

      it 'returns a corresponding status' do
        expect(start_container[:status]).to eq(:timeout)
      end
    end

    context 'when the container terminates timely' do
      it "returns the container's output" do
        expect(start_container[:stderr]).to be_blank
        expect(start_container[:stdout]).to start_with('root')
      end

      it 'returns a corresponding status' do
        expect(start_container[:status]).to eq(:ok)
      end
    end
  end
end
