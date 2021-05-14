# frozen_string_literal: true

class ExerciseTag < ApplicationRecord
  belongs_to :tag
  belongs_to :exercise

  before_save :destroy_if_empty_exercise_or_tag

  private

  def destroy_if_empty_exercise_or_tag
    destroy if exercise_id.blank? || tag_id.blank?
  end
end
