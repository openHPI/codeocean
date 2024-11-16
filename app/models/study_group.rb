# frozen_string_literal: true

class StudyGroup < ApplicationRecord
  has_many :study_group_memberships, dependent: :destroy
  has_many :external_users, through: :study_group_memberships, source_type: 'ExternalUser', source: :user
  has_many :internal_users, through: :study_group_memberships, source_type: 'InternalUser', source: :user
  has_many :submissions, dependent: :nullify
  has_many :remote_evaluation_mappings, dependent: :nullify
  has_many :subscriptions, dependent: :nullify
  has_many :authentication_tokens, dependent: :nullify
  has_many :lti_parameters, dependent: :delete_all
  has_many :events
  has_many :events_synchronized_editor, class_name: 'Event::SynchronizedEditor'
  has_many :pair_programming_exercise_feedbacks
  belongs_to :consumer

  def users
    external_users + internal_users
  end

  def to_s
    name.presence || "#{model_name.human} #{id}"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[consumer]
  end
end
