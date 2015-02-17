require 'rails_helper'

describe ExecutionEnvironment do
  let(:execution_environment) { described_class.create }

  it 'validates that the Docker image works', docker: true do
    expect(execution_environment).to receive(:validate_docker_image?).and_return(true)
    expect(execution_environment).to receive(:working_docker_image?)
    execution_environment.update(docker_image: FactoryGirl.attributes_for(:ruby)[:docker_image])
  end

  it 'validates the presence of a Docker image name' do
    expect(execution_environment.errors[:docker_image]).to be_present
  end

  it 'validates the presence of a name' do
    expect(execution_environment.errors[:name]).to be_present
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
    expect(execution_environment.errors[:user_id]).to be_present
    expect(execution_environment.errors[:user_type]).to be_present
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

    it 'is true otherwise' do
      execution_environment.docker_image = FactoryGirl.attributes_for(:ruby)[:docker_image]
      allow(Rails.env).to receive(:test?).and_return(false)
      expect(execution_environment.send(:validate_docker_image?)).to be true
    end
  end

  describe '#working_docker_image?', docker: true do
    let(:working_docker_image?) { execution_environment.send(:working_docker_image?) }
    before(:each) { expect(DockerClient).to receive(:find_image_by_tag).and_return(Object.new) }

    it 'instantiates a Docker client' do
      expect(DockerClient).to receive(:new).with(execution_environment: execution_environment).and_call_original
      expect_any_instance_of(DockerClient).to receive(:execute_arbitrary_command).and_return({})
      working_docker_image?
    end

    it 'executes the validation command' do
      expect_any_instance_of(DockerClient).to receive(:execute_arbitrary_command).with(ExecutionEnvironment::VALIDATION_COMMAND).and_return({})
      working_docker_image?
    end

    context 'when the command produces an error' do
      it 'adds an error' do
        expect_any_instance_of(DockerClient).to receive(:execute_arbitrary_command).and_return(stderr: 'command not found')
        working_docker_image?
        expect(execution_environment.errors[:docker_image]).to be_present
      end
    end

    context 'when the Docker client produces an error' do
      it 'adds an error' do
        expect_any_instance_of(DockerClient).to receive(:execute_arbitrary_command).and_raise(DockerClient::Error)
        working_docker_image?
        expect(execution_environment.errors[:docker_image]).to be_present
      end
    end
  end
end
