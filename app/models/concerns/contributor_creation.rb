# frozen_string_literal: true

module ContributorCreation
  extend ActiveSupport::Concern
  include Contributor

  included do
    belongs_to :contributor, polymorphic: true
    alias_method :user, :contributor
    alias_method :user=, :contributor=
    alias_method :author, :user
    alias_method :creator, :user
  end
end
