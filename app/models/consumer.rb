# frozen_string_literal: true

class Consumer < ApplicationRecord
  has_many :users

  scope :with_internal_users, -> { where('id IN (SELECT DISTINCT consumer_id FROM internal_users)') }
  scope :with_external_users, -> { where('id IN (SELECT DISTINCT consumer_id FROM external_users)') }
  scope :with_study_groups, -> { where('id IN (SELECT DISTINCT consumer_id FROM study_groups)') }

  validates :name, presence: true
  validates :oauth_key, presence: true, uniqueness: true
  validates :oauth_secret, presence: true

  def to_s
    name
  end
end
