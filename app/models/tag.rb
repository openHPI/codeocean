# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :exercise_tags
  has_many :exercises, through: :exercise_tags

  validates :name, uniqueness: true

  before_destroy :can_be_destroyed?, prepend: true

  def can_be_destroyed?
    exercises.none?
  end

  def to_s
    name
  end
end
