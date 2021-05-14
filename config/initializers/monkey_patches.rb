# frozen_string_literal: true

unless Array.respond_to?(:average)
  class Array
    def average
      sum / length if present?
    end
  end
end

module I18n
  def self.translation_present?(key)
    t(key, default: '').present?
  end
end
