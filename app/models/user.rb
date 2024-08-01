# frozen_string_literal: true

class User < Contributor
  self.abstract_class = true

  attr_reader :current_study_group_id

  belongs_to :consumer
  has_many :authentication_token, dependent: :destroy
  has_many :comments, as: :user
  has_many :study_group_memberships, as: :user
  has_many :study_groups, through: :study_group_memberships, as: :user
  has_many :programming_group_memberships, as: :user
  has_many :programming_groups, through: :programming_group_memberships, as: :user
  has_many :exercises, as: :user
  has_many :file_types, as: :user
  has_many :participations, through: :submissions, source: :exercise, as: :user
  has_many :user_proxy_exercise_exercises, as: :user
  has_many :testruns, as: :user
  has_many :interventions, through: :user_exercise_interventions
  has_many :remote_evaluation_mappings, as: :user
  has_many :request_for_comments, as: :user
  has_many :events
  has_many :events_synchronized_editor, class_name: 'Event::SynchronizedEditor'
  has_many :pair_programming_exercise_feedbacks
  has_many :pair_programming_waiting_users
  has_one :codeharbor_link, dependent: :destroy
  accepts_nested_attributes_for :user_proxy_exercise_exercises

  validates :platform_admin, inclusion: [true, false]

  def learner?
    return true if current_study_group_id.nil?
    return @learner if defined? @learner

    @learner = current_study_group_membership.exists?(role: :learner) && !platform_admin?
  end

  def teacher?
    return @teacher if defined? @teacher

    @teacher = current_study_group_membership.exists?(role: :teacher) && !platform_admin?
  end

  def admin?
    return @admin if defined? @admin

    @admin = platform_admin?
  end

  def id_with_type
    self.class.name.downcase.first + id.to_s
  end

  def store_current_study_group_id(study_group_id)
    @current_study_group_id = study_group_id
    self
  end

  def current_study_group_membership
    # We use `where(...).limit(1)` instead of `find_by(...)` to allow query chaining
    study_group_memberships.where(study_group: current_study_group_id).limit(1)
  end

  def study_group_ids_as_teacher
    @study_group_ids_as_teacher ||= study_group_memberships.where(role: :teacher).pluck(:study_group_id)
  end

  def study_group_ids_as_learner
    @study_group_ids_as_learner ||= study_group_memberships.where(role: :learner).pluck(:study_group_id)
  end

  def self.find_by_id_with_type(id_with_type)
    if id_with_type[0].casecmp('e').zero?
      ExternalUser.find(id_with_type[1..])
    elsif id_with_type[0].casecmp('i').zero?
      InternalUser.find(id_with_type[1..])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def self.ransackable_attributes(auth_object)
    if auth_object.present? && auth_object.admin?
      %w[name email external_id consumer_id platform_admin id]
    else
      %w[name external_id consumer_id id]
    end
  end
end
