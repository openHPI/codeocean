class User < ApplicationRecord
  self.abstract_class = true

  ROLES = %w(admin teacher)

  belongs_to :consumer
  has_many :exercises, as: :user
  has_many :file_types, as: :user
  has_many :submissions, as: :user
  has_many :participations, through: :submissions, source: :exercise, as: :user
  has_many :user_proxy_exercise_exercises, as: :user
  has_many :user_exercise_interventions, as: :user
  has_many :interventions, through: :user_exercise_interventions
  accepts_nested_attributes_for :user_proxy_exercise_exercises


  scope :with_submissions, -> { where('id IN (SELECT user_id FROM submissions)') }

  ROLES.each do |role|
    define_method("#{role}?") { try(:role) == role }
  end

  def internal_user?
    is_a?(InternalUser)
  end

  def external_user?
    is_a?(ExternalUser)
  end

  def to_s
    displayname
  end
end
