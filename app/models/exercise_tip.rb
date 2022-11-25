# frozen_string_literal: true

class ExerciseTip < ApplicationRecord
  belongs_to :exercise
  belongs_to :tip
  belongs_to :parent_exercise_tip, class_name: 'ExerciseTip', optional: true
  attr_accessor :children

  # Ensure no parent tip is set if current tip has rank == 1
  validates :rank, exclusion: {in: [1]}, if: :parent_exercise_tip_id?

  validate :tip_chain?, if: :parent_exercise_tip_id?

  def tip_chain?
    # Ensure each referenced parent exercise tip is set for this exercise
    unless ExerciseTip.exists?(
      exercise:, id: parent_exercise_tip
    )
      errors.add :parent_exercise_tip,
        I18n.t('activerecord.errors.messages.together',
          attribute: I18n.t('activerecord.attributes.exercise_tip.tip'))
    end
  end
end
