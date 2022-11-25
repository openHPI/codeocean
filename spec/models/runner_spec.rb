# frozen_string_literal: true

require 'rails_helper'

describe Runner do
  let(:runner_id) { attributes_for(:runner)[:runner_id] }
  let(:strategy_class) { described_class.strategy_class }
  let(:strategy) { instance_double(strategy_class) }

  describe 'attribute validation' do
    let(:runner) { create(:runner) }

    it 'validates the presence of the runner id' do
      described_class.skip_callback(:validation, :before, :request_id)
      runner.update(runner_id: nil)
      expect(runner.errors[:runner_id]).to be_present
      described_class.set_callback(:validation, :before, :request_id)
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

  describe '::strategy_class' do
    shared_examples 'uses the strategy defined in the constant' do |strategy, strategy_class|
      let(:codeocean_config) { instance_double(CodeOcean::Config) }
      let(:runner_management_config) { {runner_management: {enabled: true, strategy:}} }

      before do
        # Ensure to reset the memorized helper
        described_class.instance_variable_set :@strategy_class, nil
        allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
        allow(codeocean_config).to receive(:read).and_return(runner_management_config)
      end

      it "uses #{strategy_class} as strategy class for constant #{strategy}" do
        expect(described_class.strategy_class).to eq(strategy_class)
      end
    end

    available_strategies = {
      poseidon: Runner::Strategy::Poseidon,
      docker_container_pool: Runner::Strategy::DockerContainerPool,
    }
    available_strategies.each do |strategy, strategy_class|
      it_behaves_like 'uses the strategy defined in the constant', strategy, strategy_class
    end
  end

  describe '#destroy_at_management' do
    let(:runner) { described_class.create }

    before do
      allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
      allow(strategy_class).to receive(:new).and_return(strategy)
    end

    it 'delegates to its strategy' do
      expect(strategy).to receive(:destroy_at_management)
      runner.destroy_at_management
    end
  end

  describe '#attach to execution' do
    let(:runner) { described_class.create }
    let(:command) { 'ls' }
    let(:event_loop) { instance_double(Runner::EventLoop) }
    let(:connection) { instance_double(Runner::Connection) }

    before do
      allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
      allow(strategy_class).to receive(:new).and_return(strategy)
      allow(event_loop).to receive(:wait)
      allow(connection).to receive(:error).and_return(nil)
      allow(Runner::EventLoop).to receive(:new).and_return(event_loop)
      allow(strategy).to receive(:attach_to_execution).and_return(connection)
    end

    it 'delegates to its strategy' do
      expect(strategy).to receive(:attach_to_execution)
      runner.attach_to_execution(command)
    end

    it 'returns the execution time' do
      starting_time = Time.zone.now
      execution_time = runner.attach_to_execution(command)
      test_time = Time.zone.now - starting_time
      expect(execution_time).to be_between(0.0, test_time).exclusive
    end

    it 'blocks until the event loop is stopped' do
      allow(event_loop).to receive(:wait) { sleep(1) }
      execution_time = runner.attach_to_execution(command)
      expect(execution_time).to be > 1
    end

    context 'when an error is returned' do
      let(:error_message) { 'timeout' }
      let(:error) { Runner::Error::ExecutionTimeout.new(error_message) }

      before { allow(connection).to receive(:error).and_return(error) }

      it 'raises the error' do
        expect { runner.attach_to_execution(command) }.to raise_error do |raised_error|
          expect(raised_error).to be_a(Runner::Error::ExecutionTimeout)
          expect(raised_error.message).to eq(error_message)
        end
      end

      it 'attaches the execution time to the error' do
        test_starting_time = Time.zone.now
        expect { runner.attach_to_execution(command) }.to raise_error do |raised_error|
          test_time = Time.zone.now - test_starting_time
          expect(raised_error.execution_duration).to be_between(0.0, test_time).exclusive
          # The `starting_time` is shortly after the `test_starting_time``
          expect(raised_error.starting_time).to be > test_starting_time
        end
      end
    end
  end

  describe '#copy_files' do
    let(:runner) { described_class.create }

    before do
      allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
      allow(strategy_class).to receive(:new).and_return(strategy)
    end

    it 'delegates to its strategy' do
      expect(strategy).to receive(:copy_files).once
      runner.copy_files(nil)
    end

    context 'when a RunnerNotFound exception is raised' do
      before do
        was_called = false
        allow(strategy).to receive(:copy_files) do
          unless was_called
            was_called = true
            raise Runner::Error::RunnerNotFound.new
          end
        end
      end

      it 'requests a new id' do
        expect(runner).to receive(:request_new_id)
        runner.copy_files(nil)
      end

      it 'calls copy_file twice' do
        # copy_files is called again after a new runner was requested.
        expect(strategy).to receive(:copy_files).twice
        runner.copy_files(nil)
      end
    end
  end

  describe 'creation' do
    let(:user) { create(:external_user) }
    let(:execution_environment) { create(:ruby) }
    let(:create_action) { -> { described_class.create(user:, execution_environment:) } }

    it 'requests a runner id from the runner management' do
      expect(strategy_class).to receive(:request_from_management)
      create_action.call
    end

    it 'returns a valid runner' do
      allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
      expect(create_action.call).to be_valid
    end

    it 'sets the strategy' do
      allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
      strategy = strategy_class.new(runner_id, execution_environment)
      allow(strategy_class).to receive(:new).with(runner_id, execution_environment).and_return(strategy)
      runner = create_action.call
      expect(runner.strategy).to eq(strategy)
    end

    it 'does not call the runner management again while a runner id is set' do
      expect(strategy_class).to receive(:request_from_management).and_return(runner_id).once
      runner = create_action.call
      runner.update(user: create(:external_user))
    end
  end

  describe '#request_new_id' do
    let(:runner) { create(:runner) }

    context 'when the environment is available in the runner management' do
      it 'requests the runner management' do
        expect(strategy_class).to receive(:request_from_management)
        runner.send(:request_new_id)
      end

      it 'updates the runner id' do
        allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
        runner.send(:request_new_id)
        expect(runner.runner_id).to eq(runner_id)
      end

      it 'updates the strategy' do
        allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
        strategy = strategy_class.new(runner_id, runner.execution_environment)
        allow(strategy_class).to receive(:new).with(runner_id, runner.execution_environment).and_return(strategy)
        runner.send(:request_new_id)
        expect(runner.strategy).to eq(strategy)
      end
    end

    context 'when the environment could not be found in the runner management' do
      let(:environment_id) { runner.execution_environment.id }

      before { allow(strategy_class).to receive(:request_from_management).and_raise(Runner::Error::EnvironmentNotFound) }

      it 'syncs the execution environment' do
        expect(strategy_class).to receive(:sync_environment).with(runner.execution_environment)
        runner.send(:request_new_id)
      rescue Runner::Error::EnvironmentNotFound
        # Ignored because this error is expected (see tests below).
      end

      it 'raises an error when the environment could be synced' do
        allow(strategy_class).to receive(:sync_environment).with(runner.execution_environment).and_return(true)
        expect { runner.send(:request_new_id) }.to raise_error(Runner::Error::EnvironmentNotFound, /#{environment_id}.*successfully synced/)
      end

      it 'raises an error when the environment could not be synced' do
        allow(strategy_class).to receive(:sync_environment).with(runner.execution_environment).and_raise(Runner::Error::EnvironmentNotFound)
        expect { runner.send(:request_new_id) }.to raise_error(Runner::Error::EnvironmentNotFound, /#{environment_id}.*could not be synced/)
      end
    end
  end

  describe '::for' do
    let(:user) { create(:external_user) }
    let(:exercise) { create(:fibonacci) }

    context 'when the runner could not be saved' do
      before { allow(strategy_class).to receive(:request_from_management).and_return(nil) }

      it 'raises an error' do
        expect { described_class.for(user, exercise.execution_environment) }.to raise_error(Runner::Error::Unknown, /could not be saved/)
      end
    end

    context 'when a runner already exists' do
      let!(:existing_runner) { create(:runner, user:, execution_environment: exercise.execution_environment) }

      it 'returns the existing runner' do
        new_runner = described_class.for(user, exercise.execution_environment)
        expect(new_runner).to eq(existing_runner)
      end

      it 'sets the strategy' do
        runner = described_class.for(user, exercise.execution_environment)
        expect(runner.strategy).to be_present
      end
    end

    context 'when no runner exists' do
      before { allow(strategy_class).to receive(:request_from_management).and_return(runner_id) }

      it 'returns a new runner' do
        runner = described_class.for(user, exercise.execution_environment)
        expect(runner).to be_valid
      end
    end
  end
end
