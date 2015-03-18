module ActiveModel
  module Validations
    class BooleanPresenceValidator < EachValidator
      def validate(record)
        [attributes].flatten.each do |attribute|
          value = record.send(:read_attribute_for_validation, attribute)
          record.errors.add(attribute, nil, options) unless [false, true].include?(value)
        end
      end
    end
  end
end
