require 'rails_helper'

describe DockerContainerMixin do
  [:binds, :port_bindings].each do |method|
    describe "##{method}" do
      let(:data) { [] }

      it 'is defined for Docker::Container' do
        expect(Docker::Container.instance_methods).to include(method)
      end

      it 'returns the correct information' do
        expect(CONTAINER).to receive(:json).and_return('HostConfig' => {method.to_s.camelize => data})
        expect(CONTAINER.send(method)).to eq(data)
      end
    end
  end
end
