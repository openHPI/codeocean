# frozen_string_literal: true

module ContributorCreation
  extend ActiveSupport::Concern
  include Contributor

  ALLOWED_CONTRIBUTOR_TYPES = [InternalUser, ExternalUser, ProgrammingGroup].map(&:to_s).freeze

  included do
    belongs_to :contributor, polymorphic: true
    alias_method :user, :contributor
    alias_method :user=, :contributor=
    alias_method :author, :user
    alias_method :creator, :user

    validates :contributor_type, inclusion: {in: ALLOWED_CONTRIBUTOR_TYPES}
  end
end
