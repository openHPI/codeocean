unless Array.respond_to?(:average)
  class Array
    def average
      inject(:+) / length unless blank?
    end
  end
end

unless Array.respond_to?(:to_h)
  class Array
    def to_h
      Hash[self]
    end
  end
end

module I18n
  def self.translation_present?(key)
    t(key, default: '').present?
  end
end
