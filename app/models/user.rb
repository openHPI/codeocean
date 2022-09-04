# frozen_string_literal: true

class User < ApplicationRecord
  self.abstract_class = true

  ROLES = %w[admin teacher learner].freeze

  belongs_to :consumer
  has_many :authentication_token, dependent: :destroy
  has_many :study_group_memberships, as: :user
  has_many :study_groups, through: :study_group_memberships, as: :user
  has_many :exercises, as: :user
  has_many :file_types, as: :user
  has_many :submissions, as: :user
  has_many :participations, through: :submissions, source: :exercise, as: :user
  has_many :user_proxy_exercise_exercises, as: :user
  has_many :user_exercise_interventions, as: :user
  has_many :interventions, through: :user_exercise_interventions
  has_many :remote_evaluation_mappings, as: :user
  has_one :codeharbor_link, dependent: :destroy
  accepts_nested_attributes_for :user_proxy_exercise_exercises

  scope :with_submissions, -> { where('id IN (SELECT user_id FROM submissions)') }

  scope :in_study_group_of, lambda {|user|
                              joins(:study_group_memberships).where(study_group_memberships: {study_group_id: user.study_groups}) unless user.admin?
                            }

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

  def self.ransackable_attributes(auth_object)
    if auth_object.admin?
      %w[name email external_id consumer_id role]
    else
      %w[name external_id]
    end
  end
end
