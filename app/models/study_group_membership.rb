# frozen_string_literal: true

class StudyGroupMembership < ApplicationRecord
  include Creation
  belongs_to :study_group

  before_save :destroy_if_empty_study_group_or_user

  ROLES = %w[learner teacher].freeze

  def destroy_if_empty_study_group_or_user
    destroy if study_group.blank? || user.blank?
  end

  enum :role, {
    learner: 0,
    teacher: 1,
  }, default: :learner, prefix: true

  validates :role, presence: true
  validates :user_id, uniqueness: {scope: %i[user_type study_group_id]}
end
