# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_validation :strip_strings
  before_validation :remove_null_bytes

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

  def remove_null_bytes
    # remove null bytes from string attributes
    attribute_names.each do |name|
      if send(name.to_sym).respond_to?(:tr)
        send("#{name}=".to_sym, send(name).tr("\0", ''))
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
