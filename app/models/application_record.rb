# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_validation :strip_strings

  def strip_strings
    # trim whitespace from beginning and end of string attributes
    attribute_names.each do |name|
      if send(name.to_sym).respond_to?(:strip)
        send("#{name}=".to_sym, send(name).strip)
      end
    end
  end
end
