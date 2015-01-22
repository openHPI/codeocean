require 'rails_helper'

describe NonceStore do
  let(:nonce) { SecureRandom.hex }

  describe '.add' do
    it 'stores a nonce in the cache' do
      expect(Rails.cache).to receive(:write)
      NonceStore.add(nonce)
    end
  end

  describe '.delete' do
    it 'deletes a nonce from the cache' do
      expect(Rails.cache).to receive(:write)
      NonceStore.add(nonce)
      NonceStore.delete(nonce)
      expect(NonceStore.has?(nonce)).to be false
    end
  end

  describe '.has?' do
    it 'returns true for present nonces' do
      NonceStore.add(nonce)
      expect(NonceStore.has?(nonce)).to be true
    end

    it 'returns false for expired nonces' do
      Lti.send(:remove_const, 'MAXIMUM_SESSION_AGE')
      Lti::MAXIMUM_SESSION_AGE = 1
      NonceStore.add(nonce)
      expect(NonceStore.has?(nonce)).to be true
      sleep(Lti::MAXIMUM_SESSION_AGE)
      expect(NonceStore.has?(nonce)).to be false
    end

    it 'returns false for absent nonces' do
      expect(NonceStore.has?(nonce)).to be false
    end
  end
end
