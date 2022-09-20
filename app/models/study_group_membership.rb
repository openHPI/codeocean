# frozen_string_literal: true

class StudyGroupMembership < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :study_group

  enum role: {
    learner: 0,
    teacher: 1,
  }, _default: :learner, _prefix: true

  validates :role, presence: true
  validates :user_id, uniqueness: {scope: %i[user_type study_group_id]}
end
