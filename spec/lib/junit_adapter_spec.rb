require 'rails_helper'

describe JunitAdapter do
  let(:adapter) { described_class.new }

  describe '#parse_output' do
    context 'with failed tests' do
      let(:count) { 42 }
      let(:failed) { 25 }
      let(:stdout) { "FAILURES!!!\nTests run: #{count},  Failures: #{failed}" }
      let(:error_matches) { [] }

      it 'returns the correct numbers' do
        expect(adapter.parse_output(stdout: stdout)).to eq(count: count, failed: failed, error_messages: error_matches)
      end
    end

    context 'without failed tests' do
      let(:count) { 42 }
      let(:stdout) { "OK (#{count} tests)" }

      it 'returns the correct numbers' do
        expect(adapter.parse_output(stdout: stdout)).to eq(count: count, passed: count)
      end
    end
  end
end
