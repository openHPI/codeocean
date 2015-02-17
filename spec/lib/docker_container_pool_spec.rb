require 'rails_helper'

describe DockerContainerPool do
  let(:container) { double }

  def reload_class
    load('docker_container_pool.rb')
  end
  private :reload_class

  before(:each) do
    @execution_environment = FactoryGirl.create(:ruby)
    reload_class
  end

  it 'uses thread-safe data structures' do
    expect(described_class.instance_variable_get(:@containers)).to be_a(ThreadSafe::Hash)
    expect(described_class.instance_variable_get(:@containers)[@execution_environment.id]).to be_a(ThreadSafe::Array)
  end

  describe '.clean_up' do
    before(:each) { described_class.instance_variable_set(:@refill_task, double) }
    after(:each) { described_class.clean_up }

    it 'stops the refill task' do
      expect(described_class.instance_variable_get(:@refill_task)).to receive(:shutdown)
    end

    it 'destroys all containers' do
      described_class.instance_variable_get(:@containers).values.flatten.each do |container|
        expect(DockerClient).to receive(:destroy_container).with(container)
      end
    end
  end

  describe '.get_container' do
    context 'when active' do
      before(:each) do
        expect(described_class).to receive(:config).and_return(active: true)
      end

      context 'with an available container' do
        before(:each) { described_class.instance_variable_get(:@containers)[@execution_environment.id].push(container) }

        it 'takes a container from the pool' do
          expect(described_class).not_to receive(:create_container).with(@execution_environment)
          expect(described_class.get_container(@execution_environment)).to eq(container)
        end
      end

      context 'without an available container' do
        before(:each) do
          expect(described_class.instance_variable_get(:@containers)[@execution_environment.id]).to be_empty
        end

        it 'creates a new container' do
          expect(described_class).to receive(:create_container).with(@execution_environment)
          described_class.get_container(@execution_environment)
        end
      end
    end

    context 'when inactive' do
      before(:each) do
        expect(described_class).to receive(:config).and_return(active: false)
      end

      it 'creates a new container' do
        expect(described_class).to receive(:create_container).with(@execution_environment)
        described_class.get_container(@execution_environment)
      end
    end
  end

  describe '.quantities' do
    it 'maps execution environments to quantities of available containers' do
      expect(described_class.quantities.keys).to eq(ExecutionEnvironment.all.map(&:id))
      expect(described_class.quantities.values.uniq).to eq([0])
    end
  end

  describe '.refill' do
    let(:config) { double }
    let(:maximum_refill_count) { 5 }

    before(:each) do
      expect(described_class).to receive(:config).and_return(config)
      expect(config).to receive(:[]).with(:maximum_refill_count).and_return(maximum_refill_count)
    end

    after(:each) { described_class.refill }

    it 'regards all execution environments' do
      ExecutionEnvironment.all.each do |execution_environment|
        expect(described_class.instance_variable_get(:@containers)).to receive(:[]).with(execution_environment.id).and_call_original
      end
    end

    context 'with something to refill' do
      before(:each) { @execution_environment.update(pool_size: 10) }

      it 'complies with the maximum batch size' do
        expect_any_instance_of(Concurrent::Future).to receive(:execute) do |future|
          expect(described_class).to receive(:create_container).with(@execution_environment).exactly(maximum_refill_count).times
          future.instance_variable_get(:@task).call
        end
      end

      it 'works asynchronously' do
        expect(Concurrent::Future).to receive(:execute)
      end
    end

    context 'with nothing to refill' do
      before(:each) { @execution_environment.update(pool_size: 0) }

      it 'does nothing' do
        expect(Concurrent::Future).not_to receive(:execute)
      end
    end
  end

  describe '.start_refill_task' do
    after(:each) { described_class.start_refill_task }

    it 'creates an asynchronous task' do
      expect(Concurrent::TimerTask).to receive(:new).and_call_original
    end

    it 'executes the task' do
      expect_any_instance_of(Concurrent::TimerTask).to receive(:execute)
    end
  end
end
