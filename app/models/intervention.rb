# frozen_string_literal: true

class Intervention < ApplicationRecord
  has_many :user_exercise_interventions
  has_many :users, through: :user_exercise_interventions, source_type: 'ExternalUser'

  def to_s
    name
  end

  def self.create_default_interventions
    %w[BreakIntervention QuestionIntervention].each do |name|
      Intervention.find_or_create_by(name:)
    end
  end
end
