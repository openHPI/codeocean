require 'rails_helper'

describe PortPool do
  describe '.available_port' do
    it 'is synchronized' do
      expect(PortPool.instance_variable_get(:@mutex)).to receive(:synchronize)
      PortPool.available_port
    end

    context 'when a port is available' do
      it 'returns the port' do
        expect(PortPool.available_port).to be_a(Numeric)
      end

      it 'removes the port from the list of available ports' do
        port = PortPool.available_port
        expect(PortPool.instance_variable_get(:@available_ports)).not_to include(port)
      end
    end

    context 'when no port is available' do
      it 'returns the port' do
        available_ports = PortPool.instance_variable_get(:@available_ports)
        PortPool.instance_variable_set(:@available_ports, [])
        expect(PortPool.available_port).to be_nil
        PortPool.instance_variable_set(:@available_ports, available_ports)
      end
    end
  end

  describe '.release' do
    context 'when the port has been obtained earlier' do
      it 'adds the port to the list of available ports' do
        port = PortPool.available_port
        expect(PortPool.instance_variable_get(:@available_ports)).not_to include(port)
        PortPool.release(port)
        expect(PortPool.instance_variable_get(:@available_ports)).to include(port)
      end
    end

    context 'when the port has not been obtained earlier' do
      it 'does not add the port to the list of available ports' do
        port = PortPool.instance_variable_get(:@available_ports).sample
        expect { PortPool.release(port) }.not_to change { PortPool.instance_variable_get(:@available_ports).length }
      end
    end

    context 'when the port is not included in the port range' do
      it 'does not add the port to the list of available ports' do
        port = nil
        expect { PortPool.release(port) }.not_to change { PortPool.instance_variable_get(:@available_ports).length }
      end
    end
  end
end
