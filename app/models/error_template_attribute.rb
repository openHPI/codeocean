# frozen_string_literal: true

class ErrorTemplateAttribute < ApplicationRecord
  has_and_belongs_to_many :error_template

  def to_s
    key
  end
end
