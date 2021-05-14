# frozen_string_literal: true

class StudyGroupMembership < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :study_group

  validates :user_id, uniqueness: {scope: %i[user_type study_group_id]}
end
