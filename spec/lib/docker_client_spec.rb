require 'rails_helper'
require 'seeds_helper'

describe DockerClient, docker: true do
  let(:command) { 'whoami' }
  let(:docker_client) { described_class.new(execution_environment: FactoryBot.build(:java), user: FactoryBot.build(:admin)) }
  let(:execution_environment) { FactoryBot.build(:java) }
  let(:image) { double }
  let(:submission) { FactoryBot.create(:submission) }
  let(:workspace_path) { '/tmp' }

  describe '.check_availability!' do
    context 'when a socket error occurs' do
      it 'raises an error' do
        expect(Docker).to receive(:version).and_raise(Excon::Errors::SocketError.new(StandardError.new))
        expect { described_class.check_availability! }.to raise_error(DockerClient::Error)
      end
    end

    context 'when a timeout occurs' do
      it 'raises an error' do
        expect(Docker).to receive(:version).and_raise(Timeout::Error)
        expect { described_class.check_availability! }.to raise_error(DockerClient::Error)
      end
    end
  end

  describe '.container_creation_options' do
    let(:container_creation_options) { described_class.container_creation_options(execution_environment) }

    it 'specifies the Docker image' do
      expect(container_creation_options).to include('Image' => described_class.find_image_by_tag(execution_environment.docker_image).info['RepoTags'].first)
    end

    it 'specifies the memory limit' do
      expect(container_creation_options).to include('Memory' => execution_environment.memory_limit.megabytes)
    end

    it 'specifies whether network access is enabled' do
      expect(container_creation_options).to include('NetworkDisabled' => !execution_environment.network_enabled?)
    end

    it 'specifies to open the standard input stream once' do
      expect(container_creation_options).to include('OpenStdin' => true, 'StdinOnce' => true)
    end
  end

  describe '.container_start_options' do
    let(:container_start_options) { described_class.container_start_options(execution_environment, '') }

    it 'specifies mapped directories' do
      expect(container_start_options).to include('Binds' => kind_of(Array))
    end

    it 'specifies mapped ports' do
      expect(container_start_options).to include('PortBindings' => kind_of(Hash))
    end
  end

  describe '.create_container' do
    let(:create_container) { described_class.create_container(execution_environment) }

    it 'uses the correct Docker image' do
      expect(described_class).to receive(:find_image_by_tag).with(execution_environment.docker_image).and_call_original
      create_container
    end

    it 'creates a unique directory' do
      expect(described_class).to receive(:generate_local_workspace_path).and_call_original
      expect(FileUtils).to receive(:mkdir).with(kind_of(String)).and_call_original
      create_container
    end

    it 'creates a container' do
      expect(described_class).to receive(:container_creation_options).with(execution_environment).and_call_original
      expect(Docker::Container).to receive(:create).with(kind_of(Hash)).and_call_original
      create_container
    end

    it 'starts the container' do
      expect(described_class).to receive(:container_start_options).with(execution_environment, kind_of(String)).and_call_original
      expect_any_instance_of(Docker::Container).to receive(:start).with(kind_of(Hash)).and_call_original
      create_container
    end

    it 'configures mapped directories' do
      expect(described_class).to receive(:mapped_directories).and_call_original
      create_container
    end

    it 'configures mapped ports' do
      expect(described_class).to receive(:mapped_ports).with(execution_environment).and_call_original
      create_container
    end

    context 'when an error occurs' do
      let(:error) { Docker::Error::NotFoundError.new }

      context 'when retries are left' do
        before(:each) do
          expect(described_class).to receive(:mapped_directories).and_raise(error).and_call_original
        end

        it 'retries to create a container' do
          expect(create_container).to be_a(Docker::Container)
        end
      end

      context 'when no retries are left' do
        before(:each) do
          expect(described_class).to receive(:mapped_directories).exactly(DockerClient::RETRY_COUNT + 1).times.and_raise(error)
        end

        it 'raises the error' do
          pending('RETRY COUNT is disabled')
          expect { create_container }.to raise_error(error)
        end
      end
    end
  end

  describe '#create_workspace_files' do
    let(:container) { double }

    before(:each) do
      expect(container).to receive(:binds).at_least(:once).and_return(["#{workspace_path}:#{DockerClient::CONTAINER_WORKSPACE_PATH}"])
    end

    after(:each) { docker_client.send(:create_workspace_files, container, submission) }

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
    let(:file) { FactoryBot.build(:file, content: 'puts 42') }
    let(:file_path) { File.join(workspace_path, file.name_with_extension) }
    after(:each) { File.delete(file_path) }

    it 'creates a file' do
      expect(described_class).to receive(:local_workspace_path).at_least(:once).and_return(workspace_path)
      docker_client.send(:create_workspace_file, container: CONTAINER, file: file)
      expect(File.exist?(file_path)).to be true
      expect(File.new(file_path, 'r').read).to eq(file.content)
    end
  end

  describe '.destroy_container' do
    let(:container) { described_class.create_container(execution_environment) }
    after(:each) { described_class.destroy_container(container) }

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
      expect(described_class).to receive(:local_workspace_path).at_least(:once).and_return(workspace_path)
      #!TODO Fix this
      #expect(PathName).to receive(:rmtree).with(workspace_path)
    end

    it 'deletes the container' do
      expect(container).to receive(:delete).with(force: true, v: true)
    end
  end

  describe '#execute_arbitrary_command' do
    let(:execute_arbitrary_command) { docker_client.execute_arbitrary_command(command) }

    it 'takes a container from the pool' do
      expect(DockerContainerPool).to receive(:get_container).and_call_original
      execute_arbitrary_command
    end

    it 'sends the command' do
      expect(docker_client).to receive(:send_command).with(command, kind_of(Docker::Container))
      execute_arbitrary_command
    end

    context 'when a socket error occurs' do
      let(:error) { Excon::Errors::SocketError.new(SocketError.new) }

      context 'when retries are left' do
        let(:result) { 42 }

        before(:each) do
          expect(docker_client).to receive(:send_command).and_raise(error).and_return(result)
        end

        it 'retries to execute the command' do
          expect(execute_arbitrary_command).to eq(result)
        end
      end

      context 'when no retries are left' do
        before(:each) do
          expect(docker_client).to receive(:send_command).exactly(DockerClient::RETRY_COUNT + 1).times.and_raise(error)
        end

        it 'raises the error' do
          pending("retries are disabled")
          #!TODO Retries is disabled
          #expect { execute_arbitrary_command }.to raise_error(error)
        end
      end
    end
  end

  describe '#execute_run_command' do
    let(:filename) { submission.exercise.files.detect { |file| file.role == 'main_file' }.name_with_extension }
    after(:each) { docker_client.send(:execute_run_command, submission, filename) }

    it 'takes a container from the pool' do
      pending("todo in the future")
      expect(DockerContainerPool).to receive(:get_container).with(submission.execution_environment).and_call_original
    end

    it 'creates the workspace files' do
      pending("todo in the future")
      expect(docker_client).to receive(:create_workspace_files)
    end

    it 'executes the run command' do
      pending("todo in the future")
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

    it 'creates the workspace files' do
      expect(docker_client).to receive(:create_workspace_files)
    end

    it 'executes the test command' do
      expect(submission.execution_environment).to receive(:test_command).and_call_original
      expect(docker_client).to receive(:send_command).with(kind_of(String), kind_of(Docker::Container))
    end
  end

  describe '.generate_local_workspace_path' do
    it 'includes the correct workspace root' do
      expect(described_class.generate_local_workspace_path).to start_with(DockerClient::LOCAL_WORKSPACE_ROOT.to_s)
    end

    it 'includes a UUID' do
      expect(SecureRandom).to receive(:uuid).and_call_original
      described_class.generate_local_workspace_path
    end
  end

  describe '.initialize_environment' do
    context 'with complete configuration' do
      it 'creates the file directory' do
        expect(FileUtils).to receive(:mkdir_p).with(DockerClient::LOCAL_WORKSPACE_ROOT)
        described_class.initialize_environment
      end
    end

    context 'with incomplete configuration' do
      before(:each) { expect(described_class).to receive(:config).at_least(:once).and_return({}) }

      it 'raises an error' do
        expect { described_class.initialize_environment }.to raise_error(DockerClient::Error)
      end
    end
  end

  describe '.local_workspace_path' do
    let(:container) { described_class.create_container(execution_environment) }
    let(:local_workspace_path) { described_class.local_workspace_path(container) }

    it 'returns a path' do
      expect(local_workspace_path).to be_a(Pathname)
    end

    it 'includes the correct workspace root' do
      expect(local_workspace_path.to_s).to start_with(DockerClient::LOCAL_WORKSPACE_ROOT.to_s)
    end
  end

  describe '.mapped_directories' do
    it 'returns a unique mapping' do
      mapping = described_class.mapped_directories(workspace_path).first
      expect(mapping).to start_with(workspace_path)
      expect(mapping).to end_with(DockerClient::CONTAINER_WORKSPACE_PATH)
    end
  end

  describe '.mapped_ports' do
    context 'with exposed ports' do
      before(:each) { execution_environment.exposed_ports = '3000' }

      it 'returns a mapping' do
        expect(described_class.mapped_ports(execution_environment)).to be_a(Hash)
        expect(described_class.mapped_ports(execution_environment).length).to eq(1)
      end

      it 'retrieves available ports' do
        expect(PortPool).to receive(:available_port)
        described_class.mapped_ports(execution_environment)
      end
    end

    context 'without exposed ports' do
      it 'returns an empty mapping' do
        expect(described_class.mapped_ports(execution_environment)).to eq({})
      end
    end
  end

  describe '#send_command' do
    let(:block) { proc {} }
    let(:container) { described_class.create_container(execution_environment) }
    let(:send_command) { docker_client.send(:send_command, command, container, &block) }
    after(:each) { send_command }

    it 'limits the execution time' do
      expect(Timeout).to receive(:timeout).at_least(:once).with(kind_of(Numeric)).and_call_original
    end

    it 'provides the command to be executed as input' do
      pending("we are currently not using any input and for output server send events instead of attach.")
      expect(container).to receive(:attach).with(stdin: kind_of(StringIO))
    end

    it 'calls the block' do
      pending("block is no longer called, see revision 4cbf9970b13362efd4588392cafe4f7fd7cb31c3 to get information how it was done before.")
      expect(block).to receive(:call)
    end

    context 'when a timeout occurs' do
      before(:each) { expect(container).to receive(:exec).and_raise(Timeout::Error) }

      it 'destroys the container asynchronously' do
        pending("Container is destroyed, but not as expected in this test. ToDo update this test.")
        expect(Concurrent::Future).to receive(:execute)
      end

      it 'returns a corresponding status' do
        expect(send_command[:status]).to eq(:timeout)
      end
    end

    context 'when the container terminates timely' do
      it 'destroys the container asynchronously' do
        pending("Container is destroyed, but not as expected in this test. ToDo update this test.")
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
