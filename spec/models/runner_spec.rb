# frozen_string_literal: true

require 'rails_helper'

describe Runner do
  let(:runner_id) { FactoryBot.attributes_for(:runner)[:runner_id] }
  let(:strategy_class) { described_class.strategy_class }

  describe 'attribute validation' do
    let(:runner) { FactoryBot.create :runner }

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
      it "uses #{strategy_class} as strategy class for constant #{strategy}" do
        stub_const('Runner::STRATEGY_NAME', strategy)
        expect(described_class.strategy_class).to eq(strategy_class)
      end
    end

    {poseidon: Runner::Strategy::Poseidon, docker: Runner::Strategy::Docker}.each do |strategy, strategy_class|
      include_examples 'uses the strategy defined in the constant', strategy, strategy_class
    end

    shared_examples 'delegates method sends to its strategy' do |method, *args|
      context "when sending #{method}" do
        let(:strategy) { instance_double(strategy_class) }
        let(:runner) { described_class.create }

        before do
          allow(strategy_class).to receive(:request_from_management).and_return(runner_id)
          allow(strategy_class).to receive(:new).and_return(strategy)
        end

        it "delegates the method #{method}" do
          expect(strategy).to receive(method)
          runner.send(method, *args)
        end
      end
    end

    include_examples 'delegates method sends to its strategy', :destroy_at_management
    include_examples 'delegates method sends to its strategy', :copy_files, nil
    include_examples 'delegates method sends to its strategy', :attach_to_execution, nil
  end

  describe 'creation' do
    let(:user) { FactoryBot.create :external_user }
    let(:execution_environment) { FactoryBot.create :ruby }
    let(:create_action) { -> { described_class.create(user: user, execution_environment: execution_environment) } }

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
      runner.update(user: FactoryBot.create(:external_user))
    end
  end

  describe '#request_new_id' do
    let(:runner) { FactoryBot.create :runner }

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
        allow(strategy_class).to receive(:sync_environment).with(runner.execution_environment).and_return(false)
        expect { runner.send(:request_new_id) }.to raise_error(Runner::Error::EnvironmentNotFound, /#{environment_id}.*could not be synced/)
      end
    end
  end

  describe '::for' do
    let(:user) { FactoryBot.create :external_user }
    let(:exercise) { FactoryBot.create :fibonacci }

    context 'when the runner could not be saved' do
      before { allow(strategy_class).to receive(:request_from_management).and_return(nil) }

      it 'raises an error' do
        expect { described_class.for(user, exercise) }.to raise_error(Runner::Error::Unknown, /could not be saved/)
      end
    end

    context 'when a runner already exists' do
      let!(:existing_runner) { FactoryBot.create(:runner, user: user, execution_environment: exercise.execution_environment) }

      it 'returns the existing runner' do
        new_runner = described_class.for(user, exercise)
        expect(new_runner).to eq(existing_runner)
      end

      it 'sets the strategy' do
        runner = described_class.for(user, exercise)
        expect(runner.strategy).to be_present
      end
    end

    context 'when no runner exists' do
      before { allow(strategy_class).to receive(:request_from_management).and_return(runner_id) }

      it 'returns a new runner' do
        runner = described_class.for(user, exercise)
        expect(runner).to be_valid
      end
    end
  end
end
