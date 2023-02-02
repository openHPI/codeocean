# frozen_string_literal: true

class User < ApplicationRecord
  self.abstract_class = true

  attr_reader :current_study_group_id

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
                              unless user.admin?
                                joins(:study_group_memberships)
                                  .where(study_group_memberships: {
                                    study_group_id: user.study_group_memberships
                                                        .where(study_group_memberships: {role: StudyGroupMembership.roles[:teacher]})
                                                        .select(:study_group_id),
                                  })
                              end
                            }

  validates :platform_admin, inclusion: [true, false]

  def internal_user?
    is_a?(InternalUser)
  end

  def external_user?
    is_a?(ExternalUser)
  end

  def learner?
    return true if current_study_group_id.nil?

    @learner ||= current_study_group_membership.exists?(role: :learner) && !platform_admin?
  end

  def teacher?
    @teacher ||= current_study_group_membership.exists?(role: :teacher) && !platform_admin?
  end

  def admin?
    @admin ||= platform_admin?
  end

  def store_current_study_group_id(study_group_id)
    @current_study_group_id = study_group_id
    self
  end

  def current_study_group_membership
    # We use `where(...).limit(1)` instead of `find_by(...)` to allow query chaining
    study_group_memberships.where(study_group: current_study_group_id).limit(1)
  end

  def to_s
    displayname
  end

  def to_sentry_context
    {
      id:,
      type: self.class.name,
      consumer: consumer.name,
    }
  end

  def self.ransackable_attributes(auth_object)
    if auth_object.present? && auth_object.admin?
      %w[name email external_id consumer_id platform_admin]
    else
      %w[name external_id]
    end
  end
end
