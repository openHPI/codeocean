# frozen_string_literal: true

class StudyGroup < ApplicationRecord
  has_many :study_group_memberships, dependent: :destroy
  has_many :external_users, through: :study_group_memberships, source_type: 'ExternalUser', source: :user
  has_many :internal_users, through: :study_group_memberships, source_type: 'InternalUser', source: :user
  has_many :submissions, dependent: :nullify
  belongs_to :consumer

  def users
    external_users + internal_users
  end

  def user_count
    external_users.count + internal_users.count
  end

  def to_s
    name.presence || "StudyGroup #{id}"
  end
end
