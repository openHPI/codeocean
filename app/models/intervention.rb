# frozen_string_literal: true

class Intervention < ApplicationRecord
  has_many :user_exercise_interventions
  has_many :external_users, through: :user_exercise_interventions, source: :contributor, source_type: 'ExternalUser'
  has_many :internal_users, through: :user_exercise_interventions, source: :contributor, source_type: 'InternalUser'
  has_many :programming_groups, through: :user_exercise_interventions, source: :contributor, source_type: 'ProgrammingGroup'

  def to_s
    name
  end

  def contributors
    @contributors ||= internal_users.distinct + external_users.distinct + programming_groups.distinct
  end

  def self.create_default_interventions
    %w[BreakIntervention QuestionIntervention].each do |name|
      Intervention.find_or_create_by(name:)
    end
  end
end
