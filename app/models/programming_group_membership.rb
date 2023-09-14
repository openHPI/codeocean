# frozen_string_literal: true

class ProgrammingGroupMembership < ApplicationRecord
  include Creation
  belongs_to :programming_group

  validate :unique_membership_for_exercise
  validates :user_id, uniqueness: {scope: %i[programming_group_id user_type]}

  def unique_membership_for_exercise
    if user.programming_groups.where(exercise: programming_group.exercise).any?
      errors.add(:base, :already_exists, id_with_type: user.id_with_type)
    end
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
