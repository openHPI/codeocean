# frozen_string_literal: true

module Creation
  extend ActiveSupport::Concern

  included do
    belongs_to :user, polymorphic: true
    alias_method :author, :user
    alias_method :creator, :user
  end
end
