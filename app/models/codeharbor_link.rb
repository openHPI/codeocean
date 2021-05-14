# frozen_string_literal: true

class CodeharborLink < ApplicationRecord
  validates :push_url, presence: true
  validates :check_uuid_url, presence: true
  validates :api_key, presence: true

  belongs_to :user, class_name: 'InternalUser'

  delegate :to_s, to: :id
end
