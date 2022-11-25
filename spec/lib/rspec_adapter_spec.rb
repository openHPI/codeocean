# frozen_string_literal: true

require 'rails_helper'

describe RspecAdapter do
  let(:adapter) { described_class.new }
  let(:count) { 42 }
  let(:failed) { 25 }
  let(:stdout) { "Finished in 0.1 seconds (files took 0.1 seconds to load)\n#{count} examples, #{failed} failures" }

  describe '#parse_output' do
    it 'returns the correct numbers' do
      expect(adapter.parse_output(stdout:)).to eq(count:, failed:)
    end
  end
end
