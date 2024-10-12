# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JunitAdapter do
  let(:adapter) { described_class.new }

  describe '#parse_output' do
    context 'with failed tests' do
      let(:count) { 42 }
      let(:failed) { 25 }
      let(:stdout) { "FAILURES!!!\nTests run: #{count},  Failures: #{failed}" }

      it 'returns the correct numbers' do
        expect(adapter.parse_output(stdout:)).to eq(count:, failed:)
      end
    end

    context 'without failed tests' do
      let(:count) { 42 }
      let(:stdout) { "OK (#{count} tests)" }

      it 'returns the correct numbers' do
        expect(adapter.parse_output(stdout:)).to eq(count:, passed: count)
      end
    end
  end
end
