# frozen_string_literal: true

module Creation
  extend ActiveSupport::Concern

  ALLOWED_USER_TYPES = [InternalUser, ExternalUser].map(&:to_s).freeze

  included do
    belongs_to :user, polymorphic: true
    alias_method :author, :user
    alias_method :creator, :user

    validates :user_type, inclusion: {in: ALLOWED_USER_TYPES}
  end
end
