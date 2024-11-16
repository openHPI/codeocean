# frozen_string_literal: true

class ErrorTemplate < ApplicationRecord
  belongs_to :execution_environment
  has_and_belongs_to_many :error_template_attributes

  delegate :to_s, to: :name
end
