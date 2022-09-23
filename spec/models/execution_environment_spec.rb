# frozen_string_literal: true

require 'rails_helper'

describe ExecutionEnvironment do
  let(:execution_environment) { described_class.create.tap {|execution_environment| execution_environment.update(network_enabled: nil, privileged_execution: nil) } }

  it 'validates that the Docker image works' do
    allow(execution_environment).to receive(:validate_docker_image?).and_return(true)
    allow(execution_environment).to receive(:working_docker_image?).and_return(true)
    execution_environment.update(build(:ruby).attributes)
    expect(execution_environment).to have_received(:working_docker_image?)
  end

  it 'validates the presence of a Docker image name' do
    expect(execution_environment.errors[:docker_image]).to be_present
  end

  it 'validates the minimum value of the memory limit' do
    execution_environment.update(memory_limit: ExecutionEnvironment::MINIMUM_MEMORY_LIMIT / 2)
    expect(execution_environment.errors[:memory_limit]).to be_present
  end

  it 'validates the numericality of the memory limit' do
    execution_environment.update(memory_limit: Math::PI)
    expect(execution_environment.errors[:memory_limit]).to be_present
  end

  it 'validates the presence of a memory limit' do
    execution_environment.update(memory_limit: nil)
    expect(execution_environment.errors[:memory_limit]).to be_present
  end

  it 'validates the minimum value of the cpu limit' do
    execution_environment.update(cpu_limit: 0)
    expect(execution_environment.errors[:cpu_limit]).to be_present
  end

  it 'validates that cpu limit is an integer' do
    execution_environment.update(cpu_limit: Math::PI)
    expect(execution_environment.errors[:cpu_limit]).to be_present
  end

  it 'validates the presence of a cpu limit' do
    execution_environment.update(cpu_limit: nil)
    expect(execution_environment.errors[:cpu_limit]).to be_present
  end

  it 'validates the presence of a name' do
    expect(execution_environment.errors[:name]).to be_present
  end

  it 'validates the presence of the network enabled flag' do
    expect(execution_environment.errors[:network_enabled]).to be_present
    execution_environment.update(network_enabled: false)
    expect(execution_environment.errors[:network_enabled]).to be_blank
  end

  it 'validates the presence of the privileged_execution enabled flag' do
    expect(execution_environment.errors[:privileged_execution]).to be_present
    execution_environment.update(privileged_execution: false)
    expect(execution_environment.errors[:privileged_execution]).to be_blank
  end

  it 'validates the numericality of the permitted run time' do
    execution_environment.update(permitted_execution_time: Math::PI)
    expect(execution_environment.errors[:permitted_execution_time]).to be_present
  end

  it 'validates the presence of a permitted run time' do
    execution_environment.update(permitted_execution_time: nil)
    expect(execution_environment.errors[:permitted_execution_time]).to be_present
  end

  it 'validates the numericality of the pool size' do
    execution_environment.update(pool_size: Math::PI)
    expect(execution_environment.errors[:pool_size]).to be_present
  end

  it 'validates the presence of a pool size' do
    execution_environment.update(pool_size: nil)
    expect(execution_environment.errors[:pool_size]).to be_present
  end

  it 'validates the presence of a run command' do
    expect(execution_environment.errors[:run_command]).to be_present
  end

  it 'validates the presence of a user' do
    expect(execution_environment.errors[:user]).to be_present
  end

  it 'validates the format of the exposed ports' do
    execution_environment.update(exposed_ports: '1,')
    expect(execution_environment.errors[:exposed_ports]).to be_present

    execution_environment.update(exposed_ports: '1,a')
    expect(execution_environment.errors[:exposed_ports]).to be_present
  end

  describe '#valid_test_setup?' do
    context 'with a test command and a testing framework' do
      before { execution_environment.update(test_command: attributes_for(:ruby)[:test_command], testing_framework: attributes_for(:ruby)[:testing_framework]) }

      it 'is valid' do
        expect(execution_environment.errors[:test_command]).to be_blank
      end
    end

    context 'with a test command but no testing framework' do
      before { execution_environment.update(test_command: attributes_for(:ruby)[:test_command], testing_framework: nil) }

      it 'is invalid' do
        expect(execution_environment.errors[:test_command]).to be_present
      end
    end

    context 'with no test command but a testing framework' do
      before { execution_environment.update(test_command: nil, testing_framework: attributes_for(:ruby)[:testing_framework]) }

      it 'is invalid' do
        expect(execution_environment.errors[:test_command]).to be_present
      end
    end

    context 'with no test command and no testing framework' do
      before { execution_environment.update(test_command: nil, testing_framework: nil) }

      it 'is valid' do
        expect(execution_environment.errors[:test_command]).to be_blank
      end
    end
  end

  describe '#validate_docker_image?' do
    it 'is false in the test environment' do
      expect(Rails.env.test?).to be true
      expect(execution_environment.send(:validate_docker_image?)).to be false
    end

    it 'is false without a Docker image' do
      expect(execution_environment.docker_image).to be_blank
      expect(execution_environment.send(:validate_docker_image?)).to be false
    end

    it 'is false when the pool size is empty' do
      expect(execution_environment.pool_size).to be 0
      expect(execution_environment.send(:validate_docker_image?)).to be false
    end

    it 'is true otherwise' do
      execution_environment.docker_image = attributes_for(:ruby)[:docker_image]
      execution_environment.pool_size = 1
      allow(Rails.env).to receive(:test?).and_return(false)
      expect(execution_environment.send(:validate_docker_image?)).to be true
    end
  end

  describe '#working_docker_image?' do
    let(:execution_environment) { create(:ruby) }
    let(:working_docker_image?) { execution_environment.send(:working_docker_image?) }
    let(:runner) { instance_double Runner }

    before do
      allow(execution_environment).to receive(:sync_runner_environment).and_return(true)
      allow(Runner).to receive(:for).with(execution_environment.author, execution_environment).and_return runner
    end

    it 'instantiates a Runner' do
      allow(runner).to receive(:execute_command).and_return({})
      working_docker_image?
      expect(runner).to have_received(:execute_command).once
    end

    it 'executes the validation command' do
      allow(runner).to receive(:execute_command).and_return({})
      working_docker_image?
      expect(runner).to have_received(:execute_command).with(ExecutionEnvironment::VALIDATION_COMMAND)
    end

    context 'when the command produces an error' do
      it 'adds an error' do
        allow(runner).to receive(:execute_command).and_return(stderr: 'command not found')
        working_docker_image?
        expect(execution_environment.errors[:docker_image]).to be_present
      end
    end

    context 'when the Docker client produces an error' do
      it 'adds an error' do
        allow(runner).to receive(:execute_command).and_raise(Runner::Error)
        expect { working_docker_image? }.to raise_error(ActiveRecord::RecordInvalid)
        expect(execution_environment.errors[:docker_image]).to be_present
      end
    end
  end

  describe '#exposed_ports_list' do
    it 'returns an empty string if no ports are exposed' do
      execution_environment.exposed_ports = []
      expect(execution_environment.exposed_ports_list).to eq('')
    end

    it 'returns an string with comma-separated integers representing the exposed ports' do
      execution_environment.exposed_ports = [1, 2, 3]
      expect(execution_environment.exposed_ports_list).to eq('1, 2, 3')

      execution_environment.exposed_ports.each do |port|
        expect(execution_environment.exposed_ports_list).to include(port.to_s)
      end
    end
  end
end
