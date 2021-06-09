# frozen_string_literal: true

require 'rails_helper'

describe Runner::Strategy::Docker do
  let(:runner_id) { FactoryBot.attributes_for(:runner)[:runner_id] }
  let(:execution_environment) { FactoryBot.create :ruby }
  let(:docker) { described_class.new(runner_id, execution_environment) }

  # TODO: add tests for these methods when implemented
  it 'defines all methods all runner management strategies must define' do
    expect(docker.public_methods).to include(*Runner::DELEGATED_STRATEGY_METHODS)
    expect(described_class.public_methods).to include(:request_from_management)
  end
end
