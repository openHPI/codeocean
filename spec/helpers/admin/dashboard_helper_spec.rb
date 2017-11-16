require 'rails_helper'

describe Admin::DashboardHelper do
  describe '#dashboard_data' do
    it 'includes Docker-related data' do
      expect(dashboard_data).to include(:docker)
    end
  end

  describe '#docker_data' do
    before(:each) { FactoryBot.create(:ruby) }

    it 'contains an entry for every execution environment' do
      expect(docker_data.length).to eq(ExecutionEnvironment.count)
    end

    it 'contains the pool size for every execution environment' do
      expect(docker_data.first.symbolize_keys).to include(:pool_size)
    end

    it 'contains the number of available containers for every execution environment' do
      expect(DockerContainerPool).to receive(:quantities).exactly(ExecutionEnvironment.count).times.and_call_original
      expect(docker_data.first).to include(:quantity)
    end
  end
end
