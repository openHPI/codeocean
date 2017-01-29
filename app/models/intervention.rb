class Intervention < ActiveRecord::Base

  NAME = %w(overallSlower longSession syntaxErrors videoNotWatched)

  has_many :user_exercise_interventions
  has_many :users, through: :user_exercise_interventions, source_type: "ExternalUser"
  #belongs_to :user, polymorphic: true
  #belongs_to :external_users, source: :user, source_type: ExternalUser
  #belongs_to :internal_users, source: :user, source_type: InternalUser, through: :user_interventions
 # alias_method :users, :external_users
  #has_many :exercises, through: :user_interventions

  validates :name, inclusion: {in: NAME}

end