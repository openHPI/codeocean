require 'rails_helper'

describe DockerContainerPool do
  let(:container) { double(:start_time => Time.now, :status => 'available', :json => {'State' => {'Running' => true}}) }

  def reload_class
    load('docker_container_pool.rb')
  end
  private :reload_class

  before(:each) do
    @execution_environment = FactoryBot.create(:ruby)
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

        it 'not creates a new container' do
          expect(described_class).not_to receive(:create_container).with(@execution_environment)
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
    before(:each) { @execution_environment.update(pool_size: 10) }
    after(:each) { described_class.refill }

    context 'when configured to work synchronously' do
      before(:each) do
        expect(described_class).to receive(:config).and_return(refill: {async: false})
      end

      it 'works synchronously' do
        expect(described_class).to receive(:refill_for_execution_environment)
      end
    end

    context 'when configured to work asynchronously' do
      before(:each) do
        expect(described_class).to receive(:config).and_return(refill: {async: true})
      end

      it 'works asynchronously' do
        expect_any_instance_of(Concurrent::Future).to receive(:execute) do |future|
          expect(described_class).to receive(:refill_for_execution_environment)
          future.instance_variable_get(:@task).call
        end
      end
    end
  end

  describe '.refill_for_execution_environment' do
    let(:batch_size) { 5 }

    before(:each) do
      expect(described_class).to receive(:config).and_return(refill: {batch_size: batch_size})
    end

    after(:each) { described_class.refill_for_execution_environment(@execution_environment) }

    context 'with something to refill' do
      before(:each) { @execution_environment.update(pool_size: 10) }

      it 'complies with the maximum batch size' do
        expect(described_class).to receive(:create_container).with(@execution_environment).exactly(batch_size).times
      end
    end

    context 'with nothing to refill' do
      before(:each) { @execution_environment.update(pool_size: 0) }

      it 'does nothing' do
        expect(described_class).not_to receive(:create_container)
      end
    end
  end

  describe '.start_refill_task' do
    let(:interval) { 30 }
    let(:timeout) { 60 }

    before(:each) do
      expect(described_class).to receive(:config).at_least(:once).and_return(refill: {interval: interval, timeout: timeout})
    end

    after(:each) { described_class.start_refill_task }

    # changed from false to true
    it 'creates an asynchronous task' do
      expect(Concurrent::TimerTask).to receive(:new).with(execution_interval: interval, run_now: true, timeout_interval: timeout).and_call_original
    end

    it 'executes the task' do
      expect_any_instance_of(Concurrent::TimerTask).to receive(:execute)
    end
  end
end
