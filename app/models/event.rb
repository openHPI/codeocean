# frozen_string_literal: true

class Event < ApplicationRecord
  include Creation
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'

  validates :category, presence: true
  validates :data, presence: true
end
