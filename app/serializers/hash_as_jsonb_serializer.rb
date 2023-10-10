# frozen_string_literal: true

# stolen from https://github.com/rails/rails/issues/25894#issuecomment-777516944
# this serializer can be used by a model to make sure the hash from a jsonb field can be accessed with symbols instead of string-keys.
class HashAsJsonbSerializer
  def self.dump(hash)
    hash
  end

  def self.load(hash)
    hash.is_a?(Hash) ? hash.deep_symbolize_keys : {}
  end
end
