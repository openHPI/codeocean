require 'rails_helper'

describe PyUnitAdapter do
  let(:adapter) { PyUnitAdapter.new }
  let(:count) { 42 }
  let(:failed) { 25 }
  let(:stderr) { "Ran #{count} tests in 0.1s\n\nFAILED (failures=#{failed})" }

  describe '#parse_output' do
    it 'returns the correct numbers' do
      expect(adapter.parse_output(stderr: stderr)).to eq({count: count, failed: failed})
    end
  end
end
