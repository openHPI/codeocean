# frozen_string_literal: true

class WebauthnCredential < ApplicationRecord
  belongs_to :user, polymorphic: true

  validates :external_id, :public_key, :label, :sign_count, presence: true
  validates :external_id, uniqueness: true
  validates :label, uniqueness: {scope: %i[user_id user_type]}
  validates :sign_count, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: (2**32) - 1}

  delegate :to_s, to: :label

  def self.parent_resource
    User
  end
end
