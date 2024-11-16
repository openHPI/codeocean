# frozen_string_literal: true

class CodeharborLink < ApplicationRecord
  include Creation

  validates :push_url, presence: true
  validates :check_uuid_url, presence: true
  validates :api_key, presence: true

  def to_s
    "#{model_name.human} #{id}"
  end

  def self.parent_resource
    User
  end
end
