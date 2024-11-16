# frozen_string_literal: true

class ErrorTemplateAttribute < ApplicationRecord
  has_and_belongs_to_many :error_template

  delegate :to_s, to: :key
end
