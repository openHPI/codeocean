require 'rails_helper'

describe DockerContainerMixin do
  [:binds, :port_bindings].each do |method|
    describe "##{method}" do
      it 'is defined for Docker::Container' do
        expect(Docker::Container.instance_methods).to include(method)
      end
    end
  end
end
