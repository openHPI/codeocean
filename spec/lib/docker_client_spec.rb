require 'rails_helper'
require 'seeds_helper'

describe DockerClient, docker: true do
  let(:command) { 'whoami' }
  let(:docker_client) { DockerClient.new(execution_environment: FactoryGirl.build(:ruby), user: FactoryGirl.build(:admin)) }
  let(:execution_environment) { FactoryGirl.build(:ruby) }
  let(:image) { double }
  let(:submission) { FactoryGirl.create(:submission) }
  let(:workspace_path) { '/tmp' }

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

  describe '.create_container' do
    after(:each) { DockerClient.create_container(execution_environment) }

    it 'uses the correct Docker image' do
      expect(DockerClient).to receive(:find_image_by_tag).with(execution_environment.docker_image).and_call_original
    end

    it 'creates a unique directory' do
      expect(DockerClient).to receive(:generate_local_workspace_path).and_call_original
      expect(FileUtils).to receive(:mkdir).with(kind_of(String)).and_call_original
    end

    it 'creates a container waiting for input' do
      expect(Docker::Container).to receive(:create).with('Image' => kind_of(String), 'OpenStdin' => true, 'StdinOnce' => true).and_call_original
    end

    it 'starts the container' do
      expect_any_instance_of(Docker::Container).to receive(:start)
    end

    it 'configures mapped directories' do
      expect(DockerClient).to receive(:mapped_directories).and_call_original
      expect_any_instance_of(Docker::Container).to receive(:start).with(hash_including('Binds' => kind_of(Array)))
    end

    it 'configures mapped ports' do
      expect(DockerClient).to receive(:mapped_ports).with(execution_environment).and_call_original
      expect_any_instance_of(Docker::Container).to receive(:start).with(hash_including('PortBindings' => kind_of(Hash)))
    end
  end

  describe '#create_workspace' do
    let(:container) { double }

    before(:each) do
      docker_client.instance_variable_set(:@submission, submission)
      expect(container).to receive(:binds).at_least(:once).and_return(["#{workspace_path}:#{DockerClient::CONTAINER_WORKSPACE_PATH}"])
    end

    after(:each) { docker_client.send(:create_workspace, container) }

    it 'creates submission-specific directories' do
      expect(Dir).to receive(:mkdir).at_least(:once)
    end

    it 'copies binary files' do
      submission.collect_files.select { |file| file.file_type.binary? }.each do |file|
        expect(docker_client).to receive(:copy_file_to_workspace).with(container: container, file: file)
      end
    end

    it 'creates non-binary files' do
      submission.collect_files.reject { |file| file.file_type.binary? }.each do |file|
        expect(docker_client).to receive(:create_workspace_file).with(container: container, file: file)
      end
    end
  end

  describe '#create_workspace_file' do
    let(:file) { FactoryGirl.build(:file, content: 'puts 42') }
    let(:file_path) { File.join(workspace_path, file.name_with_extension) }
    after(:each) { File.delete(file_path) }

    it 'creates a file' do
      expect(DockerClient).to receive(:local_workspace_path).at_least(:once).and_return(workspace_path)
      docker_client.send(:create_workspace_file, container: CONTAINER, file: file)
      expect(File.exist?(file_path)).to be true
      expect(File.new(file_path, 'r').read).to eq(file.content)
    end
  end

  describe '.destroy_container' do
    let(:container) { DockerClient.create_container(execution_environment) }
    after(:each) { DockerClient.destroy_container(container) }

    it 'stops the container' do
      expect(container).to receive(:stop).and_return(container)
    end

    it 'kills running processes' do
      expect(container).to receive(:kill)
    end

    it 'releases allocated ports' do
      expect(container).to receive(:port_bindings).at_least(:once).and_return(foo: [{'HostPort' => '42'}])
      expect(PortPool).to receive(:release)
    end

    it 'removes the mapped directory' do
      expect(DockerClient).to receive(:local_workspace_path).and_return(workspace_path)
      expect(FileUtils).to receive(:rm_rf).with(workspace_path)
    end

    it 'deletes the container' do
      expect(container).to receive(:delete).with(force: true)
    end
  end

  describe '#execute_arbitrary_command' do
    after(:each) { docker_client.execute_arbitrary_command(command) }

    it 'takes a container from the pool' do
      expect(DockerContainerPool).to receive(:get_container).and_call_original
    end

    it 'sends the command' do
      expect(docker_client).to receive(:send_command).with(command, kind_of(Docker::Container))
    end
  end

  describe '#execute_run_command' do
    let(:filename) { submission.exercise.files.detect { |file| file.role == 'main_file' }.name_with_extension }
    after(:each) { docker_client.send(:execute_run_command, submission, filename) }

    it 'takes a container from the pool' do
      expect(DockerContainerPool).to receive(:get_container).with(submission.execution_environment).and_call_original
    end

    it 'creates the workspace' do
      expect(docker_client).to receive(:create_workspace)
    end

    it 'executes the run command' do
      expect(submission.execution_environment).to receive(:run_command).and_call_original
      expect(docker_client).to receive(:send_command).with(kind_of(String), kind_of(Docker::Container))
    end
  end

  describe '#execute_test_command' do
    let(:filename) { submission.exercise.files.detect { |file| file.role == 'teacher_defined_test' }.name_with_extension }
    after(:each) { docker_client.send(:execute_test_command, submission, filename) }

    it 'takes a container from the pool' do
      expect(DockerContainerPool).to receive(:get_container).with(submission.execution_environment).and_call_original
    end

    it 'creates the workspace' do
      expect(docker_client).to receive(:create_workspace)
    end

    it 'executes the test command' do
      expect(submission.execution_environment).to receive(:test_command).and_call_original
      expect(docker_client).to receive(:send_command).with(kind_of(String), kind_of(Docker::Container))
    end
  end

  describe '.generate_local_workspace_path' do
    it 'includes the correct workspace root' do
      expect(DockerClient.generate_local_workspace_path).to start_with(DockerClient::LOCAL_WORKSPACE_ROOT.to_s)
    end

    it 'includes a UUID' do
      expect(SecureRandom).to receive(:uuid).and_call_original
      DockerClient.generate_local_workspace_path
    end
  end

  describe '.initialize_environment' do
    context 'with complete configuration' do
      it 'creates the file directory' do
        expect(FileUtils).to receive(:mkdir_p).with(DockerClient::LOCAL_WORKSPACE_ROOT)
        DockerClient.initialize_environment
      end
    end

    context 'with incomplete configuration' do
      before(:each) { expect(DockerClient).to receive(:config).at_least(:once).and_return({}) }

      it 'raises an error' do
        expect { DockerClient.initialize_environment }.to raise_error(DockerClient::Error)
      end
    end
  end

  describe '.local_workspace_path' do
    let(:container) { DockerClient.create_container(execution_environment) }
    let(:local_workspace_path) { DockerClient.local_workspace_path(container) }

    it 'returns a path' do
      expect(local_workspace_path).to be_a(Pathname)
    end

    it 'includes the correct workspace root' do
      expect(local_workspace_path.to_s).to start_with(DockerClient::LOCAL_WORKSPACE_ROOT.to_s)
    end
  end

  describe '.mapped_directories' do
    it 'returns a unique mapping' do
      mapping = DockerClient.mapped_directories(workspace_path).first
      expect(mapping).to start_with(workspace_path)
      expect(mapping).to end_with(DockerClient::CONTAINER_WORKSPACE_PATH)
    end
  end

  describe '.mapped_ports' do
    context 'with exposed ports' do
      before(:each) { execution_environment.exposed_ports = '3000' }

      it 'returns a mapping' do
        expect(DockerClient.mapped_ports(execution_environment)).to be_a(Hash)
        expect(DockerClient.mapped_ports(execution_environment).length).to eq(1)
      end

      it 'retrieves available ports' do
        expect(PortPool).to receive(:available_port)
        DockerClient.mapped_ports(execution_environment)
      end
    end

    context 'without exposed ports' do
      it 'returns an empty mapping' do
        expect(DockerClient.mapped_ports(execution_environment)).to eq({})
      end
    end
  end

  describe '#send_command' do
    let(:block) { Proc.new {} }
    let(:container) { DockerClient.create_container(execution_environment) }
    let(:send_command) { docker_client.send(:send_command, command, container, &block) }
    after(:each) { send_command }

    it 'limits the execution time' do
      expect(Timeout).to receive(:timeout).at_least(:once).with(kind_of(Numeric)).and_call_original
    end

    it 'provides the command to be executed as input' do
      expect(container).to receive(:attach).with(stdin: kind_of(StringIO))
    end

    it 'calls the block' do
      expect(block).to receive(:call)
    end

    context 'when a timeout occurs' do
      before(:each) { expect(container).to receive(:attach).and_raise(Timeout::Error) }

      it 'destroys the container asynchronously' do
        expect(Concurrent::Future).to receive(:execute)
      end

      it 'returns a corresponding status' do
        expect(send_command[:status]).to eq(:timeout)
      end
    end

    context 'when the container terminates timely' do
      it 'destroys the container asynchronously' do
        expect(Concurrent::Future).to receive(:execute)
      end

      it "returns the container's output" do
        expect(send_command[:stderr]).to be_blank
        expect(send_command[:stdout]).to start_with('root')
      end

      it 'returns a corresponding status' do
        expect(send_command[:status]).to eq(:ok)
      end
    end
  end
end
