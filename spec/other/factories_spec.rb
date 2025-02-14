# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Factories' do
  let(:codeocean_config) { instance_double(CodeOcean::Config) }
  let(:runner_management_config) { {runner_management: {enabled: false}} }

  before do
    allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
    allow(codeocean_config).to receive(:read).and_return(runner_management_config)
  end

  it 'are all valid', permitted_execution_time: 30 do
    expect { FactoryBot.lint }.not_to raise_error
  end
end
