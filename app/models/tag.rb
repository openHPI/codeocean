# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :exercise_tags
  has_many :exercises, through: :exercise_tags

  validates :name, uniqueness: true

  before_destroy :can_be_destroyed?, prepend: true

  delegate :to_s, to: :name

  def can_be_destroyed?
    exercises.none?
  end
end
