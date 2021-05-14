# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :exercise_tags
  has_many :exercises, through: :exercise_tags

  validates :name, uniqueness: true

  def destroy
    if can_be_destroyed?
      super
    end
  end

  def can_be_destroyed?
    exercises.none?
  end

  def to_s
    name
  end
end
