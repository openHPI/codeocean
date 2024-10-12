# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PyUnitAdapter do
  let(:adapter) { described_class.new }
  let(:count) { 42 }
  let(:failed) { 25 }
  let(:stderr) { "Ran #{count} tests in 0.1s\n\nFAILED (failures=#{failed})" }

  describe '#parse_output' do
    it 'returns the correct numbers' do
      expect(adapter.parse_output(stderr:)).to eq(count:, failed:)
    end
  end
end
