class Intervention < ActiveRecord::Base

  NAME = %w(overallSlower longSession syntaxErrors videoNotWatched)

  has_many :user_exercise_interventions
  has_many :users, through: :user_exercise_interventions, source_type: "ExternalUser"

  validates :name, inclusion: {in: NAME}

end