# frozen_string_literal: true

class Consumer < ApplicationRecord
  enum rfc_visibility: {
    all: 0,
    consumer: 1,
    study_group: 2,
  }, _default: :all, _prefix: true

  has_many :users
  has_many :study_groups, dependent: :destroy

  scope :with_internal_users, -> { where('id IN (SELECT DISTINCT consumer_id FROM internal_users)') }
  scope :with_external_users, -> { where('id IN (SELECT DISTINCT consumer_id FROM external_users)') }
  scope :with_study_groups, -> { where('id IN (SELECT DISTINCT consumer_id FROM study_groups)') }

  validates :name, presence: true
  validates :oauth_key, presence: true, uniqueness: true
  validates :oauth_secret, presence: true

  after_create :generate_internal_study_group

  def generate_internal_study_group
    StudyGroup.create!(consumer: self, name: "Default Study Group for #{name}", external_id: nil)
  end
  private :generate_internal_study_group

  def to_s
    name
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id]
  end
end
