# frozen_string_literal: true

require 'rails_helper'

describe SqlResultSetComparatorAdapter do
  let(:adapter) { described_class.new }

  describe '#parse_output' do
    context 'with missing tuples' do
      let(:stdout) { "Missing tuples: [1]\nUnexpected tuples: []" }

      it 'considers the test as failed' do
        expect(adapter.parse_output(stdout:)).to eq(count: 1, failed: 1)
      end
    end

    context 'with unexpected tuples' do
      let(:stdout) { "Missing tuples: []\nUnexpected tuples: [1]" }

      it 'considers the test as failed' do
        expect(adapter.parse_output(stdout:)).to eq(count: 1, failed: 1)
      end
    end

    context 'without missing or unexpected tuples' do
      let(:stdout) { "Missing tuples: []\nUnexpected tuples: []" }

      it 'considers the test as passed' do
        expect(adapter.parse_output(stdout:)).to eq(count: 1, passed: 1)
      end
    end
  end
end
