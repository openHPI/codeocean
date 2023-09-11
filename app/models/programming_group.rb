# frozen_string_literal: true

class ProgrammingGroup < ApplicationRecord
  include Contributor

  has_many :anomaly_notifications, as: :contributor, dependent: :destroy
  has_many :programming_group_memberships, dependent: :destroy
  has_many :external_users, through: :programming_group_memberships, source_type: 'ExternalUser', source: :user
  has_many :internal_users, through: :programming_group_memberships, source_type: 'InternalUser', source: :user
  has_many :testruns, through: :submissions
  has_many :runners, as: :contributor, dependent: :destroy
  has_many :events
  has_many :events_synchronized_editor, class_name: 'Event::SynchronizedEditor'
  has_many :pair_programming_exercise_feedbacks
  belongs_to :exercise

  validate :min_group_size
  validate :max_group_size
  validate :no_erroneous_users
  accepts_nested_attributes_for :programming_group_memberships

  def initialize(attributes = nil)
    @erroneous_users = []
    super
  end

  def external_user?
    false
  end

  def internal_user?
    false
  end

  def self.nested_resource?
    true
  end

  def programming_group?
    true
  end

  def add(user)
    # Accessing the `users` method here will preload all users, which is otherwise done during validation.
    internal_users << user if user.internal_user? && users.exclude?(user)
    external_users << user if user.external_user? && users.exclude?(user)
    user
  end

  def to_s
    displayname
  end

  def displayname
    "Programming Group #{id}"
  end

  def to_page_context
    {
      id:,
      type: self.class.name,
      consumer: '',
      displayname:,
    }
  end

  def programming_partner_ids
    users.map(&:id_with_type)
  end

  def users
    internal_users + external_users
  end

  def users=(users)
    self.internal_users = []
    self.external_users = []
    users.each do |user|
      next @erroneous_users << user unless user.is_a?(User)

      add(user)
    end
  end

  private

  def min_group_size
    if users.size < 2
      errors.add(:base, :size_too_small)
    end
  end

  def max_group_size
    if users.size > 2
      errors.add(:base, :size_too_large)
    end
  end

  def no_erroneous_users
    @erroneous_users.each do |partner_id|
      errors.add(:base, :invalid_partner_id, partner_id:)
    end
  end
end
