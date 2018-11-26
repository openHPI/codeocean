# frozen_string_literal: true

class StudyGroupMembership < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :study_group

  validates_uniqueness_of :user_id, :scope => [:user_type, :study_group_id]
end
