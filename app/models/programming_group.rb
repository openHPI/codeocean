# frozen_string_literal: true

class ProgrammingGroup < Contributor
  has_many :programming_group_memberships, dependent: :destroy
  has_many :external_users, through: :programming_group_memberships, source_type: 'ExternalUser', source: :user
  has_many :internal_users, through: :programming_group_memberships, source_type: 'InternalUser', source: :user
  has_many :testruns, through: :submissions # Only a single user starts testruns, but the group has access to them through their submissions.
  has_many :events, dependent: :destroy # Only a single user creates events, but the group might be attributed to them optionally.
  has_many :events_synchronized_editor, class_name: 'Event::SynchronizedEditor', dependent: :destroy
  has_many :pair_programming_exercise_feedbacks, dependent: :destroy
  has_many :pair_programming_waiting_users, dependent: :destroy
  belongs_to :exercise

  validate :min_group_size
  validate :max_group_size
  validate :no_erroneous_users
  accepts_nested_attributes_for :programming_group_memberships

  def learner?
    true
  end

  def teacher?
    false
  end

  def admin?
    false
  end

  def self.parent_resource
    Exercise
  end

  def add(user)
    # Accessing the `users` method here will preload all users, which is otherwise done during validation.
    internal_users << user if user.internal_user? && users.exclude?(user)
    external_users << user if user.external_user? && users.exclude?(user)
    user
  end

  def displayname
    "Programming Group #{id}"
  end

  def programming_partner_ids
    users.map(&:id_with_type)
  end

  def users
    internal_users + external_users
  end

  def users=(users)
    users&.each do |user|
      next erroneous_users << user unless user.is_a?(User)

      add(user)
    end

    # Remove all users that are no longer part of the programming group.
    programming_group_memberships.where.not(user: users).destroy_all
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[exercise programming_group_memberships]
  end

  def self.ransortable_attributes(_auth_object = nil)
    %w[id created_at]
  end

  private

  def erroneous_users
    @erroneous_users ||= []
  end

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
    erroneous_users.each do |partner_id|
      errors.add(:base, :invalid_partner_id, partner_id:)
    end
  end
end
