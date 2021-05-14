# frozen_string_literal: true

class NonceStore
  def self.build_cache_key(nonce)
    "lti_nonce_#{nonce}"
  end

  def self.add(nonce)
    Rails.cache.write(build_cache_key(nonce), Time.zone.now, expires_in: Lti::MAXIMUM_SESSION_AGE)
  end

  def self.delete(nonce)
    Rails.cache.delete(build_cache_key(nonce))
  end

  def self.has?(nonce)
    Rails.cache.exist?(build_cache_key(nonce))
  end
end
