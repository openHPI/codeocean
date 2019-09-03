# frozen_string_literal: true

class CodeharborLink < ApplicationRecord
  validates :oauth2token, presence: true

  belongs_to :user, foreign_key: :user_id, class_name: 'InternalUser'

  def to_s
    oauth2token
  end
end
