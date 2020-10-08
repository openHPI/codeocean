# frozen_string_literal: true

class Tip < ApplicationRecord
  include Creation

  has_many :exercise_tips
  has_many :exercises, through: :exercise_tips
  belongs_to :file_type, optional: true
  validates_presence_of :file_type, if: :example?
  validate :content?

  def content?
    errors.add :description, I18n.t('activerecord.errors.messages.at_least', attribute: I18n.t('activerecord.attributes.tip.example')) unless [description?, example?].include?(true)
  end

  def to_s
    if title?
      "#{I18n.t('activerecord.models.tip.one')}: #{title} (#{id})"
    else
      "#{I18n.t('activerecord.models.tip.one')} #{id}"
    end
  end

  def can_be_destroyed?
    # This tip can only be destroyed if it is no parent to any other exercise tip
    ExerciseTip.where(parent_exercise_tip: exercise_tips).none?
  end
end
