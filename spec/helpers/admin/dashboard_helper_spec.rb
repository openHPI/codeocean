# frozen_string_literal: true

require 'rails_helper'

describe Admin::DashboardHelper do
  describe '#dashboard_data' do
    it 'includes Docker-related data' do
      expect(dashboard_data).to include(:docker)
    end
  end

  describe '#docker_data' do
    before do
      create(:ruby)
      dcp = class_double Runner::Strategy::DockerContainerPool
      allow(Runner).to receive(:strategy_class).and_return dcp
      allow(dcp).to receive(:pool_size).and_return({})
    end

    it 'contains an entry for every execution environment' do
      expect(docker_data.length).to eq(ExecutionEnvironment.count)
    end

    it 'contains the pool size for every execution environment' do
      expect(docker_data.first.symbolize_keys).to include(:prewarmingPoolSize)
    end

    it 'contains the number of idle runners for every execution environment' do
      expect(docker_data.first).to include(:idleRunners)
    end

    it 'contains the number of used runners for every execution environment' do
      expect(docker_data.first).to include(:usedRunners)
    end
  end
end
