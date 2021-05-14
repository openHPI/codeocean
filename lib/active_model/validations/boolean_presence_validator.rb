# frozen_string_literal: true

module ActiveModel
  module Validations
    class BooleanPresenceValidator < EachValidator
      BOOLEAN_VALUES = [false, true].freeze

      def validate(record)
        [attributes].flatten.each do |attribute|
          value = record.send(:read_attribute_for_validation, attribute)
          record.errors.add(attribute, nil, options) unless BOOLEAN_VALUES.include?(value)
        end
      end
    end
  end
end
