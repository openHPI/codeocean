# frozen_string_literal: true

unless Array.respond_to?(:average)
  class Array
    def average
      sum / length if present?
    end
  end
end
