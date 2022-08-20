# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_validation :strip_strings

  def strip_strings
    # trim whitespace from beginning and end of string attributes
    # except for the `content` of CodeOcean::Files
    # and except the `log` of TestrunMessages or the `output` of Testruns
    attribute_names.without('content', 'log', 'output').each do |name|
      if send(name.to_sym).respond_to?(:strip)
        send("#{name}=".to_sym, send(name).strip)
      end
    end
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    []
  end
end
