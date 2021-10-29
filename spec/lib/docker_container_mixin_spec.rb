# frozen_string_literal: true

require 'rails_helper'

describe DockerContainerMixin do
  let(:container) { Docker::Container.send(:new, Docker::Connection.new('http://example.org', {}), 'id' => SecureRandom.hex) }

  describe '#binds' do
    let(:binds) { [] }

    it 'is defined for Docker::Container' do
      expect(Docker::Container.instance_methods).to include(:binds)
    end

    it 'returns the correct information' do
      allow(container).to receive(:json).and_return('HostConfig' => {'Binds' => binds})
      expect(container.binds).to eq(binds)
    end
  end

  describe '#port_bindings' do
    let(:port) { 1234 }
    let(:port_bindings) { {"#{port}/tcp" => [{'HostIp' => '', 'HostPort' => port.to_s}]} }

    it 'is defined for Docker::Container' do
      expect(Docker::Container.instance_methods).to include(:port_bindings)
    end

    it 'returns the correct information' do
      allow(container).to receive(:json).and_return('HostConfig' => {'PortBindings' => port_bindings})
      expect(container.port_bindings).to eq(port => port)
    end
  end
end
