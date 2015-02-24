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
