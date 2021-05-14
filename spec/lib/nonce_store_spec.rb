# frozen_string_literal: true

require 'rails_helper'

describe NonceStore do
  let(:nonce) { SecureRandom.hex }

  before do
    stub_const('Lti::MAXIMUM_SESSION_AGE', 1)
  end

  describe '.add' do
    it 'stores a nonce in the cache' do
      expect(Rails.cache).to receive(:write)
      described_class.add(nonce)
    end
  end

  describe '.delete' do
    it 'deletes a nonce from the cache' do
      expect(Rails.cache).to receive(:write)
      described_class.add(nonce)
      described_class.delete(nonce)
      expect(described_class.has?(nonce)).to be false
    end
  end

  describe '.has?' do
    it 'returns true for present nonces' do
      described_class.add(nonce)
      expect(described_class.has?(nonce)).to be true
    end

    it 'returns false for expired nonces' do
      described_class.add(nonce)
      expect(described_class.has?(nonce)).to be true
      sleep(Lti::MAXIMUM_SESSION_AGE)
      expect(described_class.has?(nonce)).to be false
    end

    it 'returns false for absent nonces' do
      expect(described_class.has?(nonce)).to be false
    end
  end
end
