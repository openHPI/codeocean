# frozen_string_literal: true

class ArrayValidator < ActiveModel::EachValidator
  # Taken from https://gist.github.com/justalever/73a1b36df8468ec101f54381996fb9d1

  def validate_each(record, attribute, values)
    Array(values).each do |value|
      options.each do |key, args|
        validator_options = {attributes: attribute}
        validator_options.merge!(args) if args.is_a?(Hash)

        next if value.nil? && validator_options[:allow_nil]
        next if value.blank? && validator_options[:allow_blank]

        validator_class_name = "#{key.to_s.camelize}Validator"
        validator_class = begin
          validator_class_name.constantize
        rescue NameError
          "ActiveModel::Validations::#{validator_class_name}".constantize
        end

        validator = validator_class.new(validator_options)
        validator.validate_each(record, attribute, value)
      end
    end
  end
end
