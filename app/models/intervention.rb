class Intervention < ActiveRecord::Base

  has_many :user_exercise_interventions
  has_many :users, through: :user_exercise_interventions, source_type: "ExternalUser"

  def to_s
    name
  end

  def self.createDefaultInterventions
    %w(BreakIntervention QuestionIntervention).each do |name|
      Intervention.find_or_create_by(name: name)
    end
  end

end