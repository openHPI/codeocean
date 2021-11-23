# frozen_string_literal: true

class CommunitySolutionLock < ApplicationRecord
  include Creation

  belongs_to :community_solution
  has_many :community_solution_contributions

  validates :locked_until, presence: true

  def active?
    Time.zone.now <= locked_until
  end

  def working_time
    ActiveSupport::Duration.build(locked_until - created_at)
  end
end
