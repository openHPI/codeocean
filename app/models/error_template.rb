# frozen_string_literal: true

class ErrorTemplate < ApplicationRecord
  belongs_to :execution_environment
  has_and_belongs_to_many :error_template_attributes

  def to_s
    name
  end
end
