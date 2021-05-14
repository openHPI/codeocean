# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File'

  validates :category, presence: true
  validates :data, presence: true
end
